clc
clear all
close all
filename = 'NOTCH.xlsx';
sheet = 'Pacientes';
xlRange = 'A2:I13';

[num txt raw] = xlsread(filename,sheet,xlRange);
Fin = [50e3 100e3 200e3 300e3 400e3 500e3 600e3 700e3 800e3 900e3];
cd('C:\Users\Admin\Documents\Mestrado-github\Iontoforese\Dados');
cd(char(raw(2,1)))
filename = 'maos.txt';
B = importdata(filename,' ');
numericData = [];
 for k=1:size(B,1)
     A(k,:) = str2num(char(strrep(B(k,:),',','.')'));
 end
[dados freq] = size(A);
x = [1:dados]';
myMap = rand(freq, 3);
numdiab = 1;
numsaud = 1;
for i = 1:size(raw)
cd('C:\Users\Admin\Documents\Mestrado-github\Iontoforese\Dados');
cd(char(raw(i,1)))
filename = 'maos.txt';
B = importdata(filename,' ');
 for k=1:size(B,1)
     A(k,:) = str2num(char(strrep(B(k,:),',','.')'));
 end
i
%  figure
% title(raw(i,1))
% hold on
 for k=1:freq
dummy = polyfit(x,A(:,k),1);
% plot(x, coefficents(1)*x + coefficents(2),'-','Color',myMap(k,:));
coefficents(k) = dummy(1);

% plot(A(:,k));
 end
 if strcmp(raw(i,7),'n') ~= 1
  ImpM(numdiab,:) = A(end,:);
  DerM(numdiab,:) = coefficents(1,:);
  numdiab = numdiab+1;
 else
  ImpMS(numsaud,:) = A(end,:);
  DerMS(numdiab,:) = coefficents(1,:);
  numsaud = numsaud+1;
end
%  legend(num2str(Fin(1)),num2str(Fin(2)),num2str(Fin(3)),num2str(Fin(4)),num2str(Fin(5)),num2str(Fin(6)),num2str(Fin(7)),num2str(Fin(8)),num2str(Fin(9)),num2str(Fin(10)))
end
numdiab = 1;
numsaud = 1;
for i = 1:size(raw)
cd('C:\Users\Admin\Documents\Mestrado-github\Iontoforese\Dados');
cd(char(raw(i,1)))
filename = 'pes.txt';
B = importdata(filename,' ');
 for k=1:size(B,1)
     A(k,:) = str2num(char(strrep(B(k,:),',','.')'));
 end
i
%  figure
% title(raw(i,1))
% hold on
 for k=1:freq
dummy = polyfit(x,A(:,k),1);
% plot(x, coefficents(1)*x + coefficents(2),'-','Color',myMap(k,:));
coefficents(k) = dummy(1);

% plot(A(:,k));
 end
 if strcmp(raw(i,7),'n') ~= 1
ImpE(numdiab,:) = A(end,:);
DerE(numdiab,:) = coefficents(1,:);
 numdiab = numdiab+1;
 else
  ImpES(numsaud,:) = A(end,:);
  DerES(numdiab,:) = coefficents(1,:);
 numsaud = numsaud+1;   
end
%  legend(num2str(Fin(1)),num2str(Fin(2)),num2str(Fin(3)),num2str(Fin(4)),num2str(Fin(5)),num2str(Fin(6)),num2str(Fin(7)),num2str(Fin(8)),num2str(Fin(9)),num2str(Fin(10)))
end
for i=1:freq
desvE(i)= std(ImpE(:,i))
medE(i) = mean(ImpE(:,i))
desvM(i)= std(ImpM(:,i))
medM(i) = mean(ImpM(:,i))
desvMS(i)= std(ImpES(:,i))
medMS(i) = mean(ImpES(:,i))
desvES(i)= std(ImpMS(:,i))
medES(i) = mean(ImpMS(:,i))

desvdE(i)= std(DerE(:,i))
meddE(i) = mean(DerE(:,i))
desvdM(i)= std(DerM(:,i))
meddM(i) = mean(DerM(:,i))
desvdMS(i)= std(DerES(:,i))
meddMS(i) = mean(DerES(:,i))
desvdES(i)= std(DerMS(:,i))
meddES(i) = mean(DerMS(:,i))
end
figure

errorbar(Fin,medE, desvE,'rx','LineWidth',3,'MarkerSize',10)
hold on
errorbar(Fin,medES, desvES,'bx','LineWidth',1,'MarkerSize',10)
legend('Com Diabétes','Saudáveis')
title ('Impedância Pés')
xlabel('Frequencia (Hz)')
ylabel('Média e desvio padrão')

figure

errorbar(Fin,medM, desvM,'rx','LineWidth',3,'MarkerSize',10)
hold on
errorbar(Fin,medMS, desvMS,'bx','LineWidth',1,'MarkerSize',10)
legend('Com Diabétes','Saudáveis')
title ('Impedância Maos')
xlabel('Frequencia (Hz)')
ylabel('Média e desvio padrão')
figure

errorbar(Fin,meddE, desvdE,'rx','LineWidth',3,'MarkerSize',10)
hold on
errorbar(Fin,meddES, desvdES,'bx','LineWidth',1,'MarkerSize',10)
legend('Com Diabétes','Saudáveis')
title ('Derivada da impedância dos Pés')
xlabel('Frequencia (Hz)')
ylabel('Média e desvio padrão')
figure

errorbar(Fin,meddM, desvdM,'rx','LineWidth',3,'MarkerSize',10)
hold on
errorbar(Fin,meddMS, desvdMS,'bx','LineWidth',1,'MarkerSize',10)
legend('Com Diabétes','Saudáveis')
title ('Derivada da impedância das Maos')
xlabel('Frequencia (Hz)')
ylabel('Média e desvio padrão')