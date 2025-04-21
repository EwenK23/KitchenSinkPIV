clear
clc

%-----USER DEFINED INPUTS
%PLOT STYLE:
displayStyle=0;    %<== 0 for image, 1 for video
%File and Frames
fileIn= "M8.MOV";
fileOut= "GlitterContour.avi";
firstFrame= 200;
frameDiff= 2;
frameGap= 5;
numFramePairs= 1;
vidSpeed= 0.25;
%Post Processing Values
magFilter= 25;       %Removes a vector from from plot if displacement
                    %is x times greater than average
%PIV Constants
winW= 128;      %PIV sample window width & height
winH= 128;
step= 64;           %step size between analysed points
xMax = winW/4;
yMax = winH/4;  %Defines size of interrogation window

%-----COLLECT FRAMES TO BE ANALYSED-----
Vid = VideoReader(fileIn);    %Select video to be analysed
xMesh = winW:step:Vid.Width-winW;    %Defines mesh array for PIV 
yMesh = winH:step:Vid.Height-winH;   %  points of analysis
xCount = length(xMesh);
yCount = length(yMesh);

%Finds mean of frames around target frames to reduce background
%interference
sumIN=zeros(Vid.Height,Vid.Width);

for i = 1:Vid.NumFrames
    mframe=im2double(read(Vid,i));
    mframe=im2gray(mframe);
    sumIN=sumIN+mframe;
end
meanIN = sumIN./Vid.NumFrames;

progress = "Completed Mean Frame Analysis"
if displayStyle==1
    vidOut = VideoWriter(fileOut);
    vidOut.FrameRate = Vid.FrameRate/frameGap*vidSpeed;
    open(vidOut)
end
%Define Variables used in Loop:
    test1(winW,winH)=0;
    test2(2*winW,2*winH)=0;
    dx(xCount,yCount)=0;
    dy(xCount,yCount)=0;
    dxy(xCount,yCount)=0;

for n = 0:(numFramePairs-1)
    %Select Video frames
    frame1 = im2double(read(Vid,(firstFrame+n*frameGap)));
    frame2 = im2double(read(Vid,(firstFrame+n*frameGap+frameDiff)));
    
    %-----IMAGE PRE PROCESSING-----
    %Convert frames to greyscale
    frame1 = im2gray(frame1);
    frame2 = im2gray(frame2);
    %Subtract mean intensity from frames
    frame1=frame1-meanIN;
    frame2=frame2-meanIN;
    %Histogram
    frame1 = adapthisteq(frame1,"NumTiles",[64,64]);
    frame2 = adapthisteq(frame2,"NumTiles",[64,64]);
    
    frame1=imadjust(frame1);
    frame2=imadjust(frame2);
    
    %-----PIV ANALYSIS-----
    %Begin Loop
    for i=1:xCount
        for j=1:yCount
            
            xMinT=xMesh(i)-xMax;
            xMaxT=xMesh(i)+xMax;
            yMinT=yMesh(j)-yMax;
            yMaxT=yMesh(j)+yMax;
    
            test1= frame1(yMinT+1:yMaxT,xMinT+1:xMaxT);
            test2= frame2((yMinT-yMax)+1:(yMaxT+yMax),(xMinT-xMax)+1:(xMaxT+xMax));
            cor = normxcorr2(test1, test2);
    
            [yPeak, xPeak] = find(cor==max(cor(:)));
            if height(yPeak)==1 && height(xPeak)==1
                xOff= xPeak-0.5*width(test2)-xMax;
                yOff= yPeak-0.5*height(test2)-yMax;
            else
                xOff= mean(xPeak)-0.5*width(test2)-xMax;
                yOff= mean(yPeak)-0.5*height(test2)-yMax;
            end
            dx(i,j)=xOff;
            dy(i,j)=yOff;
            dxy(i,j)=sqrt(dx(i,j)^2+dy(i,j)^2);
        end
    end
    
    xAvg=mean(mean(dx(:,:)));
    yAvg=mean(mean(dy(:,:)));
    avgDisp=sqrt(xAvg^2+yAvg^2);
    
    for i=1:xCount
        for j=1:yCount
            if dxy(i,j)>magFilter*avgDisp
                dx(i,j)=0;
                dy(i,j)=0;
                dxy(i,j)=0;
            end
        end
    end
    
    imshow(frame1);
    hold on
    quiver(xMesh,yMesh, transpose(dx),transpose(dy),Color='Green')
    title("Frame " + (n+1) + " of " + numFramePairs)
    hold off

    F=getframe(gcf);

    if displayStyle==0
        imgName="frame"+(n+1)+".png";
        saveas(gcf,imgName);
    else
        writeVideo(vidOut,F)
    end
    progress = "Completed Frame " + (n+1) + " of " + numFramePairs
end
if displayStyle==1
    close(vidOut)
    implay(fileOut)
end