
clear all
close all
clc
addpath(genpath(pwd));
dbstop if error
audiofolder = 'data';
if ~exist(audiofolder, 'dir')
  % If that folder doesn't exist, just start in the current folder.
  audiofolder = pwd;
end
% Get the name of the file that the user wants to use.
filename = fullfile(audiofolder, '*.wav');
[baseFileName, folder] = uigetfile(filename, 'Select a file');
if baseFileName == 0
  % User clicked the Cancel button.
  return;
end
j=2;
audio_1 = fullfile(folder, baseFileName);
 [y,fs]=  audioread(audio_1);
 X=1:1:10;
%   [y,fs]=  audioread(strcat(jj,d(j).name));
     figure;plot(y);
     xlabel('Number of samples');
     ylabel('Amplitude');
%      imwrite(figure,'image_result_p2/input_image1.png')
     % Create filename from i.
saveas(gcf,strcat(pwd,'\image_result_p4\input_image_',num2str(j),'.png'))
     %%%apply preprocessing
    output=imgaussfilt(y);
    figure;plot(output);
     xlabel('Number of samples');
     ylabel('Amplitude');
%      imwrite(figure,'image_result_p2/input_image1.png')
saveas(gcf,strcat(pwd,'\image_result_p4\preprocessing_image_',num2str(j),'.png'))
% saveas(gca, fileName);
  output=output(1:15000,:);

    %%%%%%%%%%%%%%feature_extraction
    num=1;
   FMatrix=mkmfcc(num, output,fs);
   figure;plot(FMatrix);
        xlabel('Number of samples');
     ylabel('Amplitude');
   saveas(gcf,strcat(pwd,'\image_result_p4\mfkcc_image_',num2str(j),'.png'))
 rolloffPoint = spectralRolloffPoint(output,fs);
f2=reshape(rolloffPoint,1,[]);
  figure;plot(f2);
      xlabel('Number of samples');
     ylabel('Amplitude');
       saveas(gcf,strcat(pwd,'\image_result_p4\spectral_rolloff_image_',num2str(j),'.png'))
  centroid = spectralCentroid(output,fs);
f3=centroid';
 figure;plot(f3);
      xlabel('Number of samples');
     ylabel('Amplitude');
      saveas(gcf,strcat(pwd,'\image_result_p4\spectral_centroid_image_',num2str(j),'.png'))
     flatness = spectralFlatness(output,fs);
 figure;plot(flatness);
      xlabel('Number of samples');
     ylabel('Amplitude');
      saveas(gcf,strcat(pwd,'\image_result_p4\spectral_flatness_image_',num2str(j),'.png'))
      %%%%fft
      %%%fft
 F = fft(output);
 pow = F.*conj(F);
%  f10=mean(pow);
  figure;semilogy(pow);
      xlabel('Fequency');
     ylabel('Amplitude');
    
      saveas(gcf,strcat(pwd,'\image_result_p4\fft_image_',num2str(j),'.png'))
      
      %%%%