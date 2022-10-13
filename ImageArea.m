clear
clc
close

addpath img

%% init values
format shortG
minArea=10;
maxArea=1000000;
threshold=255*0.45; 
dir='img/S1_01.tif';

%% import image
    % as image
    img.Data=imread(dir);
    img.Size=size(img.Data);
    
    %as blocked image
    % bImage=blockedImage(dir);
    % bigimageshow(bImage);

    %visualization
    figure
    subplot(3,3,1)
    imshow(img.Data)
    title("1 original image")
    hrect = drawrectangle('Position', [500 500 700 700]); % for locating
    
    
%% pre-processing
    % crop image
	cimg.Data=imcrop(img.Data,[0.5000 0.5000 1024 677.5000]);
    cimg.Size=size(cimg.Data);
    subplot(3,3,2)
    imshow(cimg.Data)
    title("2 cropped image")
    
    % find image px to real unit scale
    Scaleimg.Data=imcrop(img.Data,[4.7781 719.8364 209.2714 17.1125]);
    Scaleimg.Size=size(Scaleimg.Data);
    subplot(3,3,8)
    imshow(Scaleimg.Data)
    title("ruler length")
    
    % measure line length in px
    firstpx=[];
    lastpx=[];

    for iy=1:Scaleimg.Size(2)
        if Scaleimg.Data(Scaleimg.Size(1)/2,iy)<=255/2
            if isempty(firstpx)
                firstpx=iy;
            else
                lastpx=iy;
            end
        end
    end
    rulerLength=lastpx-firstpx;

    
    % find measured scale (OCR)
    Unitimg.Data=imcrop(img.Data,[17.8571 690.2437 113.8274 22.9490]);
    Unitimg.Size=size(Unitimg.Data);
	subplot(3,3,7)
    imshow(Unitimg.Data)
    title("unit (for OCR)")
    Result=ocr(Unitimg.Data,'CharacterSet','0123456789pum* ','TextLayout','Block');
    str=string(Result.Text);
    str=split(str,' ');
    unit=str2double(str(1)); 
    
    % eval scaling value (pxx,pxy) -> (length,width)
    Scaler=unit/rulerLength;
    
%% locate objects
    % binarization
    for ix=1:cimg.Size(1)
        for iy=1:cimg.Size(2)
            if cimg.Data(ix,iy)<=threshold
                cimg.Data(ix,iy)=255;
            else
                cimg.Data(ix,iy)=0;
            end
        end
    end
    subplot(3,3,3)
    imshow(cimg.Data)
    title("3 binarization")
    
    % edge detection
%     cimg.Data = edge(cimg.Data,'canny');
    subplot(3,3,4)
    imshow(edge(cimg.Data,'canny'))
    title("4 edge detection (temp)")
    
 %% eval object volume (in px) 
subplot(3,3,5)
[C, h] = imcontour(cimg.Data, 1);
title("5 contour mapping")
n = 0;
i = 1;

nn(1) = C(2,1);
xx = C(1,2:nn(1)+1);
yy = C(2,2:nn(1)+1);
area(1) = polyarea(xx,yy);
while n+nn(i)+i < size(C,2)
    n = n + nn(i);
    i = i + 1;
    nn(i)= C(2,n+i);
    xx = C(1,n+i+1:n+nn(i)+i);
    yy = C(2,n+i+1:n+nn(i)+i);
    area(i) = polyarea(xx,yy)*Scaler;
end


%% post processing
% min area filter
filteredArea=area;
filteredArea(filteredArea < minArea) = [];

% max area filter
filteredArea(filteredArea > maxArea) = [];

% plot superimposed image
figure
temp=imcrop(img.Data,[0.5000 0.5000 1024 677.5000]);
RGBimg=cat(3,temp,temp,temp); % greyscale to RGB
imshow(RGBimg)
hold all
imcontour(cimg.Data, 1)
title('superimposed image')



%% Generate report
disp('-----------------------------------')
disp('short report (temp)')
disp('-----------------------------------')
disp("Ruler length: "+rulerLength+"px, Ruler Value: "+unit +strip(str(2)))
disp("Pixel size :"+Scaler)

disp("Regions: "+length(area))
disp("Avg Area: "+(sum(area)/length(area)))
disp("std: "+std(area))
disp("Min Area Filter: "+minArea)
disp("Regions(filtered): "+length(filteredArea))
disp("Avg Area (filtered): "+(sum(filteredArea)/length(filteredArea)))
disp("std(filtered): "+std(filteredArea))