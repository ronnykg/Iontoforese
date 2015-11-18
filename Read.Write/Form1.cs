using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using LibUsbDotNet;
using LibUsbDotNet.Main;
using System.Drawing.Printing;

namespace Examples
{

    public partial class Form1 : Form
    {
        public static UsbDevice MyUsbDevice;

        #region SET YOUR USB Vendor and Product ID!

        public static UsbDeviceFinder MyUsbFinder = new UsbDeviceFinder(0x04cc, 0x1a62);

        #endregion

        public Form1()
        {
            InitializeComponent();
        }
        private Button printButton = new Button();
        private PrintDocument printDocument1 = new PrintDocument();
        private void Form1_Load(object sender, EventArgs e)
        {

            printButton.Text = "Print Form";
            printButton.Click += new EventHandler(printButton_Click);
            printDocument1.PrintPage += new PrintPageEventHandler(printDocument2_PrintPage);
            this.Controls.Add(printButton);
           // label1.Text = "Hello World";
        }
        private bool _stopLoop;


        private void button1_Click(object sender, EventArgs e)
        {
            _stopLoop = false;
            this.button1.Enabled = false;
            this.button2.Enabled = true;
            float fbase = 5000;
            float[] k = { fbase, 7*fbase, 13*fbase, 21*fbase, 30*fbase, 35*fbase, 42*fbase, 49*fbase, 56*fbase, 63*fbase, 70*fbase, 77*fbase};
            double[] k_ajust1 = { 0, -0.21, -0.31, -0.65, 0, -1.09, -0.90, -1.47, -1.83, -1.86, -1.40, -2.14 };
               double[] k_ajust = { 220.7 / (2.7613-k_ajust1[0]), 220.7 / (2.79-k_ajust1[1]), 220.7 /( 1.96-k_ajust1[2]), 220.7 / (2.781-k_ajust1[3]), 220.7 / (2.761-k_ajust1[4]), 220.7 / (2.822-k_ajust1[5]), 220.7 / (1.975-k_ajust1[6]), 220.7 / (2.799-k_ajust1[7]), 220.7 / (3.125-k_ajust1[8]), 220.7 / (2.893-k_ajust1[9]), 220.7 / (2.002-k_ajust1[10]), 220.7 / (2.858-k_ajust1[11]) };
               double[] k_ajust2 = { 2.45 / 2.45, 2.45 / 0.82, 2.45 / 2.45, 2.45 / 0.5, 2.45 / 1.77, 2.45 / 0.82, 2.45 / 1.77, 2.45 / 2.54, 2.45 / 2.83, 2.45 / 0.81, 2.45 / 1.76, 2.45 / 2.54 };

            double[] d1 = new double[k.Length];
            double[] d2 = new double[k.Length];
            double[] y = new double[k.Length];
            int rfinal = 50;
            double[,] Fourier = new double[k.Length, rfinal];
            double[,] Goertzelfft = new double[k.Length, 4];

            int[] counts = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            double[] Dados1 = new double[65536];
            double[] Dados2 = new double[65536];
            double[] Dados3 = new double[65536];
            double[] SumX = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };                    //int Count = BytesReadWrite/2;
            double[] SumX2 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            double[] SumY = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            double[] SumXY = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            
            for (int r = 0; r < rfinal && !_stopLoop; r++)
            {
                ErrorCode ec = ErrorCode.None;
                //DrawIt();
                try
                {
                    // Find and open the usb device.
                    MyUsbDevice = UsbDevice.OpenUsbDevice(MyUsbFinder);

                    // If the device is open and ready
                    if (MyUsbDevice == null) throw new Exception("Device Not Found.");

                    // If this is a "whole" usb device (libusb-win32, linux libusb)
                    // it will have an IUsbDevice interface. If not (WinUSB) the 
                    // variable will be null indicating this is an interface of a 
                    // device.
                    IUsbDevice wholeUsbDevice = MyUsbDevice as IUsbDevice;
                    if (!ReferenceEquals(wholeUsbDevice, null))
                    {
                        // This is a "whole" USB device. Before it can be used, 
                        // the desired configuration and interface must be selected.

                        // Select config #1
                        wholeUsbDevice.SetConfiguration(1);

                        // Claim interface #0.
                        wholeUsbDevice.ClaimInterface(0);
                    }

                    // open read endpoint 1.
                    UsbEndpointReader reader = MyUsbDevice.OpenEndpointReader(ReadEndpointID.Ep02);

                    // open write endpoint 1.
                    UsbEndpointWriter writer = MyUsbDevice.OpenEndpointWriter(WriteEndpointID.Ep01);

                    // Remove the exepath/startup filename text from the begining of the CommandLine.
                    string cmdLine = Regex.Replace(
                       Environment.CommandLine, "^\".+?\"^.*? |^.*? ", "", RegexOptions.Singleline);

                    //if (!String.IsNullOrEmpty(cmdLine))
                    //{
                    int BytesReadWrite = 4096;
                    // int Freqs = 20;
                    int bytesWritten;

                    byte[] bytesWritten1 = new byte[BytesReadWrite];
                    for (int i = BytesReadWrite - 1; i >= 0; i--)
                    {
                        bytesWritten1[i] = 1;//(byte)i;
                    }
                    ec = writer.Write(bytesWritten1, 100, out bytesWritten);
                    //ec = writer.Write(Encoding.Default.GetBytes(cmdLine), 2000, out bytesWritten);
                    // if (ec != ErrorCode.None) throw new Exception(UsbDevice.LastErrorString);

                    byte[] readBuffer = new byte[BytesReadWrite];

                    // while (ec == ErrorCode.None && j < 5)
                    //{
                    //  j++;
                    int bytesRead;
                    //UsbTransfer usbReadTransfer;
                    // If the device hasn't sent data in the last 100 milliseconds,
                    // a timeout error (ec = IoTimedOut) will occur. 
                    //ec = reader.SubmitAsyncTransfer(readBuffer, 0, readBuffer.Length, 100, out usbReadTransfer);

                    double[] Dado1 = new double[BytesReadWrite/2];
                    double[] Dado2 = new double[BytesReadWrite/2];
                    double[] Dado3 = new double[BytesReadWrite/2];


                    float prec = 1;                  

                    chart1.Series["Imp"].Points.Clear();
                    chart1.Series["Linfit"].Points.Clear();
                    chart1.Series["Imp1"].Points.Clear();
                    chart1.Series["Linfit1"].Points.Clear();
                    chart1.Series["Imp2"].Points.Clear();
                    chart1.Series["Linfit2"].Points.Clear();
                    chart1.Titles.Clear();
                    chart2.Series["Abs"].Points.Clear();
                    chart2.Titles.Clear();
                    int[] count = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }; //Teste Goertzel
                    

                    int start_time = DateTime.Now.Millisecond;
                    ec = reader.Read(readBuffer, 100, out bytesRead);
                    int elapsed_time = DateTime.Now.Millisecond - start_time; //Takes 80ms until the end of the FORs... Way down below
                    count[0] = 0;
                    for (int i = 0; i < BytesReadWrite-1; i = i + 2) //THE LIBRARY READS 32 DATA, BUT FPGA SENDS ONLY 16, SO HALF IS JUST ZEROES (-8 was 4)
                    {
                        //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                        //if (readBuffer[i] == 1 && readBuffer[i + 8] == 16)
                        //{
                            chart1.Series["Imp"].Points.Clear();
                            //chart1.Series["Imp"].Points.AddXY(k[1], (readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec);
                            Dado1[count[0]] = (readBuffer[i + 1] * 256 + readBuffer[i]) / prec;
                            Dados1[counts[0]] = (((readBuffer[i + 1] * 256 + readBuffer[i + 0]) / prec) + Dados1[counts[0]] * (counts[0])) / (counts[0] + 1);
                            count[0]++;
                            chart2.Series["Abs"].Points.AddXY(count[0], (readBuffer[i + 1] * 256 + readBuffer[i]) / prec);

                            //chart1.Series["Imp"].Points.AddXY(k[2], (readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec);
                            //Dados2[counts[0]] = (((readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec) + Dados2[counts[0]] * (counts[0])) / (counts[0] + 1);
                           
                            //chart1.Series["Imp"].Points.AddXY(k[3], (readBuffer[i + 7] * 256 + readBuffer[i + 6]) / prec);
                           // Dados3[counts[0]] = (((readBuffer[i + 7] * 256 + readBuffer[i + 6]) / prec) + Dados3[counts[0]] * (counts[0])) / (counts[0] + 1);
                                                       /*if (i >= BytesReadWrite - 15)
                            {
                                chart2.Series["Abs"].Points.AddXY(40, readBuffer[i + 2]);
                                chart2.Series["Abs"].Points.AddXY(80, readBuffer[i + 4]);
                                chart2.Series["Abs"].Points.AddXY(120, readBuffer[i + 6]);
                            }*/
                            //i = i + 2;
                        //}
                        /*
                        else if (readBuffer[i] == 16 && readBuffer[i + 8] == 1)
                        {
                            chart1.Series["Imp"].Points.Clear();
                            //chart1.Series["Imp"].Points.AddXY(k[1], (readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec);
                            Dado1[count[0]] = (readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec;
                            Dados1[counts[0]] = (((readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec) + Dados1[counts[0]] * (counts[0])) / (counts[0] + 1);
                            count[0]++;
                            chart2.Series["Abs"].Points.AddXY(count[0], (readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec);
                            //chart1.Series["Imp"].Points.AddXY(k[2], (readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec);
                            Dados2[counts[0]] = (((readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec) + Dados2[counts[0]] * (counts[0])) / (counts[0] + 1);

                            //chart1.Series["Imp"].Points.AddXY(k[3], (readBuffer[i + 7] * 256 + readBuffer[i + 6])/prec);
                            Dados3[counts[0]] = (((readBuffer[i + 7] * 256 + readBuffer[i + 6]) / prec) + Dados3[counts[0]] * (counts[0])) / (counts[0] + 1);
                        
                            /*if (i >= BytesReadWrite - 15)
                            {
                                chart2.Series["Abs"].Points.AddXY(40, readBuffer[i + 2]);
                                chart2.Series["Abs"].Points.AddXY(80, readBuffer[i + 4]);
                                chart2.Series["Abs"].Points.AddXY(120, readBuffer[i + 6]);
                            } */
                       //     i = i + 2;
                       // }
                    
                        /*
                    else if (readBuffer[i] == 2 && readBuffer[i + 4] == 3 && readBuffer[i - 4] == 1)
                    {
                        count[1]++;
                        chart1.Series["Imp1"].Points.AddXY(count[1], readBuffer[i + 2]);
                        SumX[1] = SumX[1] + count[1];
                        SumY[1] = SumY[1] + readBuffer[i+2];
                        SumX2[1] = SumX2[1] + count[1] * count[1];
                        SumXY[1] = SumXY[1] + count[1] * readBuffer[i + 2];
                        i = i + 2;
                    }
                    else if (readBuffer[i] == 3 && readBuffer[i + 4] == 1 && readBuffer[i - 4] == 2)
                    {
                        count[2]++;
                        chart1.Series["Imp2"].Points.AddXY(count[2], readBuffer[i + 2]);
                        SumX[2] = SumX[2] + count[2];
                        SumY[2] = SumY[2] + readBuffer[i+2];
                        SumX2[2] = SumX2[2] + count[2] * count[2];
                        SumXY[2] = SumXY[2] + count[2] * readBuffer[i + 2];
                        i = i + 2;
                    }
                         * */

                    }


                    chart1.Titles.Add("Avaliação");
                    //chart2.Titles.Add("Espectroscopia");
                    
                    /*
                    for (int i = 0; i <= count[0] - 1; i++)
                    {
                        //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                        chart1.Series["Linfit"].Points.AddXY(i, Slope[0] * i + YInt[0]);
                    }
                    for (int i = 0; i <= count[1] - 1; i++)
                    {
                        //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                        chart1.Series["Linfit1"].Points.AddXY(i, Slope[1] * i + YInt[1]);
                    }
                    for (int i = 0; i <= count[2] - 1; i++)
                    {
                        //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                        chart1.Series["Linfit2"].Points.AddXY(i, Slope[2] * i + YInt[2]);
                    }
                     * */  //Não precisa plotar a curva característica



                    //label2.Text = "success: bulk read " + Convert.ToString(BytesReadWrite) + " bytes, TX+RX Bandwidth = " + Convert.ToString(((float)(BytesReadWrite / 1.024) / (float)(elapsed_time))) + "KB / s";

                    // }
                    // else
                    //     throw new Exception("Nothing to do.")as;as

                    //Form2 popup = new Form2();                                            CREATES AND SHOWS FORM
                    //    DialogResult dialogresult = popup.ShowDialog();


                    
                    double[] imagW = new double[k.Length];
                    double[] realW = new double[k.Length];
                    double[] Goertzel = new double[k.Length];
                    //Dado1[BytesReadWrite/2  -5] = 0;
                    //Dado1[BytesReadWrite/2 - 4] = 0;
                    //Dado1[BytesReadWrite/2 - 3] = 0;
                    //Dado1[BytesReadWrite/2 - 2] = 0;
                    //Dado1[BytesReadWrite/2 - 1] = 0;
                    double DataMean = Dado1.Sum() / (BytesReadWrite/8-4);
                    int loc;
                   // for (int p = 0; p < BytesReadWrite - 4; p++)
                   // {
                   //    Dado1[p] = Dado1[p] - DataMean;
                  // }
                    for (int j = 0; j < k.Length; j++)
                    {
                        realW[j] = 2 * Math.Cos(2 * Math.PI * k[j] / (27.0003e3)); //0.5389e6
                        imagW[j] = Math.Sin(2 * Math.PI * k[j] / (27.0003e3));     //62,3 Fbase = 4,2k
                        d1[j] = 0;
                        d2[j] = 0;
                        y[j] = 0;
                        for (int n = 0; n < BytesReadWrite/2-1 ; n++) //BytesReadWrite/8- 4
                        {
                            y[j] = Dado1[n] + (realW[j] * d1[j]) - d2[j];
                            d2[j] = d1[j];
                            d1[j] = y[j];
                        }
                        Goertzel[j] = Math.Sqrt((0.5 * realW[j] * d1[j] - d2[j]) * (0.5 * realW[j] * d1[j] - d2[j]) + (imagW[j] * d1[j]) * (imagW[j] * d1[j]));
                       //chart1.Series["Imp1"].Points.AddXY(k[j], Goertzel[j]/2000);
                       
                    }
                    label1.Text = "Taxa de variação0 = " + Convert.ToString(Goertzel[0]);
                    label5.Text = "Taxa de variaçãoDados = " + Convert.ToString(Dados2[counts[0]]); 
                    //label6.Text = "Taxa de variação1 = " + Convert.ToString(Goertzel[1]);
                   
                    double[] result = dft(Dado1);
                    for (int o = 1; o < BytesReadWrite/2-1; o++) //BytesReadWrite/8- 4
                    {
                        chart1.Series["Imp"].Points.AddXY(o * 2 * 27.0003e3 / BytesReadWrite, result[o]);//chart1.Series["Imp"].Points.AddXY(o *2* 0.5389e6 / BytesReadWrite, result[o]);
                    }
                    for (int jj = 0; jj < k.Length; jj++) //BytesReadWrite/8- 4 //379=5 607=2.9 1214(13)=2 1820=2.9 379=5 986=2.9 1493(92) =2 152(151!)=1(2.9) 758=3.2 1365=2.9 1971(72)=2 530=2.9
                    {
                        loc = (int)Math.Round(((k[jj] / (27.0003e3) - Math.Floor(k[jj] / (27.0003e3))) * (BytesReadWrite / 2 - 1)));
                        if (r != 0)
                        {
                            Goertzelfft[jj,3] = Goertzelfft[jj,2];
                            Goertzelfft[jj,2] = Goertzelfft[jj,1];
                            Goertzelfft[jj,1] = Goertzelfft[jj,0];
                            Goertzelfft[jj,0] = result[loc];
                        }
                        else
                        {
                            Goertzelfft[jj,3] = result[loc];
                            Goertzelfft[jj,2] = result[loc];
                            Goertzelfft[jj,1] = result[loc];
                            Goertzelfft[jj,0] = result[loc];
                        }
                        Fourier[jj,r] = (Goertzelfft[jj,3] + Goertzelfft[jj,2] + Goertzelfft[jj,1] + Goertzelfft[jj,0]) / 4;
                        chart1.Series["Imp2"].Points.AddXY(k[jj], Fourier[jj, r]*k_ajust2[jj] );//chart1.Series["Imp"].Points.AddXY(o *2* 0.5389e6 / BytesReadWrite, result[o]);
                    }


                    label6.Text = "Taxa de variação1 = " + Convert.ToString(result.Max());    
                }
                catch (Exception ex)
                {
                    //Console.WriteLine();
                    label2.Text = (ec != ErrorCode.None ? ec + ":" : String.Empty) + ex.Message;
                    //Console.WriteLine((ec != ErrorCode.None ? ec + ":" : String.Empty) + ex.Message);
                }
                finally
                {
                    if (MyUsbDevice != null)
                    {
                        if (MyUsbDevice.IsOpen)
                        {
                            // If this is a "whole" usb device (libusb-win32, linux libusb-1.0)
                            // it exposes an IUsbDevice interface. If not (WinUSB) the 
                            // 'wholeUsbDevice' variable will be null indicating this is 
                            // an interface of a device; it does not require or support 
                            // configuration and interface selection.
                            IUsbDevice wholeUsbDevice = MyUsbDevice as IUsbDevice;
                            if (!ReferenceEquals(wholeUsbDevice, null))
                            {
                                // Release interface #0.
                                wholeUsbDevice.ReleaseInterface(0);
                            }

                            MyUsbDevice.Close();
                        }
                        MyUsbDevice = null;

                        // Free usb resources
                        UsbDevice.Exit();

                    }

                    // Wait for user input..
                    //Console.ReadKey();
                }

                if (counts[0] != 65535)
                {
                    counts[0]++;
                }

                 SumX[0] = SumX[0] + counts[0];
                 SumY[0] = SumY[0] + Dados1[counts[0]]; // (readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec;
                 SumX2[0] = SumX2[0] + counts[0] * counts[0];
                 SumXY[0] = SumXY[0] + counts[0] * Dados1[counts[0]];// ((readBuffer[i + 3] * 256 + readBuffer[i + 2]) / prec);

                 SumX[1] = SumX[1] + counts[0];
                 SumY[1] = SumY[1] + Dados2[counts[0]];// (readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec;
                 SumX2[1] = SumX2[1] + counts[0] * counts[0];
                 SumXY[1] = SumXY[1] + counts[0] * Dados2[counts[0]];// ((readBuffer[i + 5] * 256 + readBuffer[i + 4]) / prec);

                 SumX[2] = SumX[2] + counts[0];
                 SumY[2] = SumY[2] + Dados3[counts[0]];// (readBuffer[i + 7] * 256 + readBuffer[i + 6]) / prec;
                 SumX2[2] = SumX2[2] + counts[0] * counts[0];
                 SumXY[2] = SumXY[2] + counts[0] * Dados3[counts[0]];// ((readBuffer[i + 7] * 256 + readBuffer[i + 6]) / prec);

                 double[] XMean = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                 double[] YMean = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                 double[] Slope = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                 double[] YInt = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

                 XMean[0] = SumX[0] / counts[0];
                 YMean[0] = SumY[0] / counts[0];
                 Slope[0] = (SumXY[0] - SumX[0] * YMean[0]) / (SumX2[0] - SumX[0] * XMean[0]);
                 YInt[0] = YMean[0] - Slope[0] * XMean[0];

                 XMean[1] = SumX[1] / counts[0];
                 YMean[1] = SumY[1] / counts[0];
                 Slope[1] = (SumXY[1] - SumX[1] * YMean[1]) / (SumX2[1] - SumX[1] * XMean[1]);
                 YInt[1] = YMean[1] - Slope[1] * XMean[1];

                 XMean[2] = SumX[2] / counts[0];
                 YMean[2] = SumY[2] / counts[0];
                 Slope[2] = (SumXY[2] - SumX[2] * YMean[2]) / (SumX2[2] - SumX[2] * XMean[2]);
                 YInt[2] = YMean[2] - Slope[2] * XMean[2];

                 //label1.Text = "Taxa de variação = " + Convert.ToString(counts[0]);

                 //label5.Text = "Taxa de variação = " + Convert.ToString(Slope[1]);

                 //label6.Text = "Taxa de variação = " + Convert.ToString(Slope[2]);
                 //if (bytesRead == 0) throw new Exception("No more bytes!");



                 label2.Text = "Concluído!";

                Application.DoEvents();
            }
           
            this.button1.Enabled = true;
            this.button2.Enabled = false;
        }
        private void pictureBox1_Click(object sender, EventArgs e)
        {

        }

        private void toolStripButton1_Click(object sender, EventArgs e)
        {

        }

        private void toolStripLabel1_Click(object sender, EventArgs e)
        {

        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Environment.Exit(0);
        }
        Bitmap memoryImage;
        private void CaptureScreen()
        {
            Graphics myGraphics = this.CreateGraphics();
            Size s = this.Size;
            memoryImage = new Bitmap(s.Width, s.Height, myGraphics);
            Graphics memoryGraphics = Graphics.FromImage(memoryImage);
            memoryGraphics.CopyFromScreen(this.Location.X, this.Location.Y, 0, 0, s);
        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {


            CaptureScreen();
            printDocument1.Print();
        }

        private void printDocument2_PrintPage(object sender, System.Drawing.Printing.PrintPageEventArgs e)
        {
            e.Graphics.DrawImage(memoryImage, 0, 0);
        }

        void printButton_Click(object sender, EventArgs e)
        {
        }

        private void backgroundWorker1_DoWork(object sender, DoWorkEventArgs e)
        {

        }

        private void label3_Click(object sender, EventArgs e)
        {

        }

        private void label3_Click_1(object sender, EventArgs e)
        {

        }

        private void button2_Click(object sender, EventArgs e)
        {

        }

        private void button2_Click_1(object sender, EventArgs e)
        {
            this.button1.Enabled = true;
            this.button2.Enabled = false;
            _stopLoop = true;
        }

        private void chart2_Click(object sender, EventArgs e)
        {

        }
        private double[] dft(double[] data)
        {
            int n = data.Length;
            int m = n;
            double[] real = new double[n];
            double[] imag = new double[n];
            double[] result = new double[m];
            double pi_div = 2.0 * Math.PI / n;
            for (int w = 0; w < m; w++)
            {
                double a = w * pi_div;
                for (int t = 0; t < n; t++)
                {
                    real[w] += data[t] * Math.Cos(a * t);
                    imag[w] += data[t] * Math.Sin(a * t);
                }
                result[w] = Math.Sqrt(real[w] * real[w] + imag[w] * imag[w]) / n;
            }
            return result;
        }
    }

}
