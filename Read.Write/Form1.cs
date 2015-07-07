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
        private void button1_Click(object sender, EventArgs e)
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
                    for (int i = BytesReadWrite-1; i >= 0; i--)
                    {
                        bytesWritten1[i] = 1;//(byte)i;
                    }
                   ec = writer.Write(bytesWritten1, 1000, out bytesWritten);
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
                                int start_time = DateTime.Now.Millisecond;

                       ec = reader.Read(readBuffer, 1000, out bytesRead);
                         int elapsed_time = DateTime.Now.Millisecond - start_time;

                         float[] SumX = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
                         //int Count = BytesReadWrite/2;
                         float[] SumX2 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                         float[] SumY = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }; 
                         float[] SumXY = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                        chart1.Series["Imp"].Points.Clear();
                        chart1.Series["Linfit"].Points.Clear();
                        chart1.Series["Imp1"].Points.Clear();
                        chart1.Series["Linfit1"].Points.Clear();
                        chart1.Series["Imp2"].Points.Clear();
                        chart1.Series["Linfit2"].Points.Clear();
                        chart1.Titles.Clear();
                        int[] count = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                        for (int i = 0; i <= BytesReadWrite - 1 - 4; i = i + 2) //THE LIBRARY READS 32 DATA, BUT FPGA SENDS ONLY 16, SO HALF IS JUST ZEROES
                        {                            
                            //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                            if (readBuffer[i] == 1 && readBuffer[i + 8] == 16)
                            {
                                count[0]++;
                                chart1.Series["Imp"].Points.AddXY(count[0], readBuffer[i + 2]);
                                SumX[0] = SumX[0] + count[0];
                                SumY[0] = SumY[0] + readBuffer[i+2];
                                SumX2[0] = SumX2[0] + count[0] * count[0];
                                SumXY[0] = SumXY[0] + count[0] * readBuffer[i + 2];

                                count[1]++;
                                chart1.Series["Imp1"].Points.AddXY(count[1], readBuffer[i + 4]);
                                SumX[1] = SumX[1] + count[1];
                                SumY[1] = SumY[1] + readBuffer[i + 4];
                                SumX2[1] = SumX2[1] + count[1] * count[1];
                                SumXY[1] = SumXY[1] + count[1] * readBuffer[i + 4];

                                count[2]++;
                                chart1.Series["Imp2"].Points.AddXY(count[2], readBuffer[i + 6]);
                                SumX[2] = SumX[2] + count[2];
                                SumY[2] = SumY[2] + readBuffer[i + 6];
                                SumX2[2] = SumX2[2] + count[2] * count[2];
                                SumXY[2] = SumXY[2] + count[2] * readBuffer[i + 6];

                                i = i + 2;
                            }
                            else if (readBuffer[i] == 16 && readBuffer[i + 8] == 1)
                            {
                                count[0]++;
                                chart1.Series["Imp"].Points.AddXY(count[0], readBuffer[i + 2]);
                                SumX[0] = SumX[0] + count[0];
                                SumY[0] = SumY[0] + readBuffer[i + 2];
                                SumX2[0] = SumX2[0] + count[0] * count[0];
                                SumXY[0] = SumXY[0] + count[0] * readBuffer[i + 2];

                                count[1]++;
                                chart1.Series["Imp1"].Points.AddXY(count[1], readBuffer[i + 4]);
                                SumX[1] = SumX[1] + count[1];
                                SumY[1] = SumY[1] + readBuffer[i + 4];
                                SumX2[1] = SumX2[1] + count[1] * count[1];
                                SumXY[1] = SumXY[1] + count[1] * readBuffer[i + 4];

                                count[2]++;
                                chart1.Series["Imp2"].Points.AddXY(count[2], readBuffer[i + 6]);
                                SumX[2] = SumX[2] + count[2];
                                SumY[2] = SumY[2] + readBuffer[i + 6];
                                SumX2[2] = SumX2[2] + count[2] * count[2];
                                SumXY[2] = SumXY[2] + count[2] * readBuffer[i + 6];

                                i = i + 2;
                            }
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
                        float[] XMean = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                        float[] YMean = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                        float[] Slope = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                        float[] YInt = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

                        XMean[0] = SumX[0] / count[0];
                        YMean[0] = SumY[0] / count[0];
                        Slope[0] = (SumXY[0] - SumX[0] * YMean[0]) / (SumX2[0] - SumX[0] * XMean[0]);
                        YInt[0] = YMean[0] - Slope[0] * XMean[0];

                        XMean[1] = SumX[1] / count[1];
                        YMean[1] = SumY[1] / count[1];
                        Slope[1] = (SumXY[1] - SumX[1] * YMean[1]) / (SumX2[1] - SumX[1] * XMean[1]);
                        YInt[1] = YMean[1] - Slope[1] * XMean[1];

                        XMean[2] = SumX[2] / count[2];
                        YMean[2] = SumY[2] / count[2];
                        Slope[2] = (SumXY[2] - SumX[2] * YMean[2]) / (SumX2[2] - SumX[2] * XMean[2]);
                        YInt[2] = YMean[2] - Slope[2] * XMean[2];
                         for (int i = 0; i <= count[0] -1; i++)
                        {                            
                            //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                            chart1.Series["Linfit"].Points.AddXY(i, Slope[0] * i + YInt[0]);
                        }
                         for (int i = 0; i <= count[1]-1; i++)
                         {
                             //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                             chart1.Series["Linfit1"].Points.AddXY(i, Slope[1] * i + YInt[1]);
                         }
                         for (int i = 0; i <= count[2]-1; i++)
                         {
                             //Console.Write(Encoding.Default.GetString(readBuffer, 0, bytesRead)); 
                             chart1.Series["Linfit2"].Points.AddXY(i, Slope[2] *i + YInt[2]);
                         }

                label1.Text = "Taxa de variação = " + Convert.ToString(Slope[0]);
                        //if (bytesRead == 0) throw new Exception("No more bytes!");
                    
                    chart1.Titles.Add("Avaliação");

                    label2.Text = "Done!";
                    //label2.Text = "success: bulk read " + Convert.ToString(BytesReadWrite) + " bytes, TX+RX Bandwidth = " + Convert.ToString(((float)(BytesReadWrite / 1.024) / (float)(elapsed_time))) + "KB / s";
               
                // }
               // else
               //     throw new Exception("Nothing to do.")as;as
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
    }

}
