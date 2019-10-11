function varargout = gui(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see Output
handles.output = hObject;
a = ones(256,256);
axes(handles.axes1);
imshow(a);
axes(handles.axes2);
imshow(a);
axes(handles.axes3);
imshow(a);
set(handles.text1,'string','');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
varargout{1} = handles.output;


% --- Executes on button press in Browse_im.
function Browse_im_Callback(hObject, eventdata, handles)
cd TestImages 
[filename, pathname] = uigetfile('*.jpg;*.bmp;*.gif', 'Pick an Image File');
    if isequal(filename,0) || isequal(pathname,0)
       warndlg('User pressed cancel');
    else
       disp(['User selected ', fullfile(pathname, filename)]);
       im = imread(filename);
      
Input=imresize(im,[512 512]);
Image=Input;
cd ..
[r c p] = size(Input);
if p==3
Image=rgb2gray(Image);
figure();
imshow(Image);
title('grayscaled image');
end
         axes(handles.axes1);
         imshow(Input);
         title('Test Image');
    end    
handles.Image = Image;
handles.filename = filename;
% Update handles structure
guidata(hObject, handles);
helpdlg('Test Image Selected');


% --- Executes on button press in database_load.
function database_load_Callback(hObject, eventdata, handles)
%%%%% Database Creation and Features Extraction
TT = [];
cd images
for i = 1 : 27
    
    str = int2str(i);
    str = strcat(str,'.jpg');
       
    img = imread(str);
    Input=imresize(img,[512 512]);
     [r c p] = size(Input);
     if p==3
     img=Input(:,:,2);
     end
     
    [irow icol] = size(img);
    % % % % % 1 level decomp
    
    [ll lh hl hh] = dwt2(img,'db3');
    s1 = [ll lh;hl hh];


   Min_val = min(min(lh));
Max_val = max(max(lh));
level = round(Max_val - Min_val);
GLCM = graycomatrix(lh,'GrayLimits',[Min_val Max_val],'NumLevels',level);
stat_feature = graycoprops(GLCM);
fea11 = stat_feature.Energy;
fea21 = stat_feature.Contrast;
fea31 = stat_feature.Correlation;
fea41=entropy(lh);
fea51 =mean(mean(lh));

F1=[fea11 fea21 fea31 fea41 fea51 ];

Min_val = min(min(hl));
Max_val = max(max(hl));
level = round(Max_val - Min_val);
GLCM = graycomatrix(hl,'GrayLimits',[Min_val Max_val],'NumLevels',level);
stat_feature = graycoprops(GLCM);
fea12 = stat_feature.Energy;
fea22 = stat_feature.Contrast;
fea32 = stat_feature.Correlation;
fea42=entropy(hl);
fea52 =mean(mean(hl));

F2=[fea12 fea22 fea32 fea42 fea52 ];

F=[F1 F2]';


%     F = [F1 F2 F3 F4 F5]';
    TT = [TT F];
end
cd ..
Database_feature=TT;
                                                                                                   
handles.Database_feature = Database_feature;
% Update handles structure
guidata(hObject, handles);
helpdlg('Database loaded sucessfully');

% --- Executes on button press in training_process.
function training_process_Callback(hObject, eventdata, handles)

features = handles.Database_feature;
Q = handles.queryfeature;

% % % % NN Training 
%%%%%% Importing Database features from workspace
[Qfeature features] = fetr(Q,features);
[r c] = size(features);
Q = Qfeature;

[r1 c1] = size(features);
str1 = 'image';
str3 = '.mat';
for i = 1:c1
    name = strcat(str1,num2str(i));
    P = features(:,i);
    save(name,'P');
end

% % % % Training in PNN
M = 3;
N =1;
[r1 c1] = size(features);
str1 = 'image';str3 = '.mat';
for i = 1:c1
    name = strcat(str1,num2str(i));
    valu = load(name);
    P(:,i) = valu.P;

    if M==0
        N =N+1;
        M = 2;
    else
       M = M-1;
    end
    T1 (1,i) = N;
end
disp(P);
disp(T1);
T1 = ind2vec(T1);

net = svm(P,T1);
handles.net = net;
% Update handles structure
guidata(hObject, handles);
helpdlg('Training Process Completed');


  
% --- Executes on button press in classify_im.
function classify_im_Callback(hObject, eventdata, handles)
Image=handles.Image;
net = handles.net;
Q = handles.queryfeature;
    out = sim(net,Q);
    out = vec2ind(out);
    result = round(out);
    
if result==1
       set(handles.text1,'string','NORMAL');
else
       set(handles.text1,'string','ABNORMAL');
       output = Lclustering(Image);
         axes(handles.axes2);
         imshow(output);

end

    
% --- Executes on button press in clear_im.
function clear_im_Callback(hObject, eventdata, handles)

set(handles.text1,'string','');
a = ones(256,256);
axes(handles.axes1);
imshow(a);
axes(handles.axes2);
imshow(a);
axes(handles.axes3);
imshow(a);



% --- Executes on button press in Fea_extr.
function Fea_extr_Callback(hObject, eventdata, handles)
% hObject    handle to Fea_extr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Image = handles.Image;

    [ll lh hl hh] = dwt2(Image,'db3');
    s1 = [ll lh;hl hh];

Min_val = min(min(lh));
Max_val = max(max(lh));
level = round(Max_val - Min_val);
GLCM = graycomatrix(lh,'GrayLimits',[Min_val Max_val],'NumLevels',level);
stat_feature = graycoprops(GLCM);
fea11 = stat_feature.Energy;
fea21 = stat_feature.Contrast;
fea31 = stat_feature.Correlation;
fea41=entropy(lh);
fea51 =mean(mean(lh));

F1=[fea11 fea21 fea31 fea41 fea51 ];

Min_val = min(min(hl));
Max_val = max(max(hl));
level = round(Max_val - Min_val);
GLCM = graycomatrix(hl,'GrayLimits',[Min_val Max_val],'NumLevels',level);
stat_feature = graycoprops(GLCM);
fea12 = stat_feature.Energy;
fea22 = stat_feature.Contrast;
fea32 = stat_feature.Correlation;
fea42=entropy(hl);
fea52 =mean(mean(hl));

F2=[fea12 fea22 fea32 fea42 fea52 ];

    Q = [F1 F2]'; 
 
    axes(handles.axes2);
    imshow(s1,[]);
    title('Wavelet');

    
handles.queryfeature=Q;
% Update handles structure
guidata(hObject, handles);

helpdlg('Features Extracted');


% --- Executes on button press in Close.
function Close_Callback(hObject, eventdata, handles)
% hObject    handle to Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close all;


% --- Executes on button press in preprocess.
function preprocess_Callback(hObject, eventdata, handles)
% hObject    handle to preprocess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
Image =handles.Image;
inp = Image;
inp_noi=imnoise(inp,'salt & pepper',0.10);
figure;
imshow(inp_noi);title('Noise Image');

%% Median Filter
NoiseLessImg=zeros(size(inp_noi,1),size(inp_noi,2));
for i=1:size(inp_noi,1)-2
    for j=1:size(inp_noi,2)-2
        LocMat=inp_noi(i:i+2,j:j+2);
        OneDimLocMat=LocMat(:);
        SortMat=sort(OneDimLocMat);
        NoiseLessImg(i,j)=SortMat(5);
    end
end
figure;
imshow(NoiseLessImg,[]);title('Noise Less Image');

%%%%%histogram equalization%%%%%
GIm=NoiseLessImg;
numofpixels=size(GIm,1)*size(GIm,2);
HIm=uint8(zeros(size(GIm,1),size(GIm,2)));
freq=zeros(256,1);
probf=zeros(256,1);
probc=zeros(256,1);
cum=zeros(256,1);
output=zeros(256,1);

for i=1:size(GIm,1)
    for j=1:size(GIm,2)
        value=GIm(i,j);
        freq(value+1)=freq(value+1)+1;
        probf(value+1)=freq(value+1)/numofpixels;
    end
end
sum=0;
no_bins=255;
%The cumulative distribution probability is calculated. 
for i=1:size(probf)
   sum=sum+freq(i);
   cum(i)=sum;
   probc(i)=cum(i)/numofpixels;
   output(i)=round(probc(i)*no_bins);
end
for i=1:size(GIm,1)
    for j=1:size(GIm,2)
            HIm(i,j)=output(GIm(i,j)+1);
    end
end

figure,imshow(HIm);
title('Histogram equalization');
guidata(hObject, handles);


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on mouse press over axes background.
function axes3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function axes3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes3



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
