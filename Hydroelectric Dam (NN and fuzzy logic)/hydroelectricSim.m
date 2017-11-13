

function varargout = hydroelectricSim(varargin)
% HYDROELECTRICSIM MATLAB code for hydroelectricSim.fig
%      HYDROELECTRICSIM, by itself, creates a new HYDROELECTRICSIM or raises the existing
%      singleton*.
%
%      H = HYDROELECTRICSIM returns the handle to a new HYDROELECTRICSIM or the handle to
%      the existing singleton*.
%
%      HYDROELECTRICSIM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HYDROELECTRICSIM.M with the given input arguments.
%
%      HYDROELECTRICSIM('Property','Value',...) creates a new HYDROELECTRICSIM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before hydroelectricSim_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to hydroelectricSim_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help hydroelectricSim

% Last Modified by GUIDE v2.5 04-Jul-2017 20:59:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @hydroelectricSim_OpeningFcn, ...
                   'gui_OutputFcn',  @hydroelectricSim_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


function FinalRes = hydroFormula(flowCFS)
    H = 92; % Gross head in Meters
    turbine = 32; %Three Gorges Dam 32 Francis Turbine
    conversionMW = 1000; %kW to MW coversion, the formula produce in kW
    Q =  flowCFS.* 0.028316847; %CFS to CMS conversion
    e = 0.80; %efficiency of the plant
    density = 9.81; %constant density and acceleration due to gravity
    P = (((Q .* H .*e .*density).*turbine)./conversionMW);
    FinalRes = round(P); %convert from double to integer


function fuzzyPred = hydroFuzzy(n)
    Fuzzy=newfis('Hydroelectric'); %create new fuzzy logic
    %initialize input 1 as previous 3 hours demand
    Fuzzy=addvar(Fuzzy,'input','Prev-demand3hrs',[10000 21000]);
    %Add 5 Triangular-membership function for the first input
    Fuzzy=addmf(Fuzzy,'input',1,'verylow','trimf',[7250 10000 12750]);
    Fuzzy=addmf(Fuzzy,'input',1,'low','trimf',[10000 12750 15500]);
    Fuzzy=addmf(Fuzzy,'input',1,'medium','trimf',[12750 15500 18250]);
    Fuzzy=addmf(Fuzzy,'input',1,'high','trimf',[15500 18250 21000]);
    Fuzzy=addmf(Fuzzy,'input',1,'veryhigh','trimf',[18250 21000 23750]);
    
    %initialize input 2 as previous 2 hours demand
    Fuzzy=addvar(Fuzzy,'input','Prev-demand2hrs',[10000 21000]);
    %Add 5 Triangular-membership function for the second input
    Fuzzy=addmf(Fuzzy,'input',2,'verylow','trimf',[7250 10000 12750]);
    Fuzzy=addmf(Fuzzy,'input',2,'low','trimf',[10000 12750 15500]);
    Fuzzy=addmf(Fuzzy,'input',2,'medium','trimf',[12750 15500 18250]);
    Fuzzy=addmf(Fuzzy,'input',2,'high','trimf',[15500 18250 21000]);
    Fuzzy=addmf(Fuzzy,'input',2,'veryhigh','trimf',[18250 21000 23750]);
    
    %initialize input 2 as previous 1 hours demand
    Fuzzy=addvar(Fuzzy,'input','Prev-demand1hr',[10000 21000]);
    %Add 5 Triangular-membership function for the third input
    Fuzzy=addmf(Fuzzy,'input',3,'verylow','trimf',[7250 10000 12750]);
    Fuzzy=addmf(Fuzzy,'input',3,'low','trimf',[10000 12750 15500]);
    Fuzzy=addmf(Fuzzy,'input',3,'medium','trimf',[12750 15500 18250]);
    Fuzzy=addmf(Fuzzy,'input',3,'high','trimf',[15500 18250 21000]);
    Fuzzy=addmf(Fuzzy,'input',3,'veryhigh','trimf',[18250 21000 23750]);

    %initialize the output as the supply in CFS
    Fuzzy=addvar(Fuzzy,'output','Supply(CFS)',[15285 34000]);
    %Add 5 Triangular-membership function for the output
    Fuzzy=addmf(Fuzzy,'output',1,'verylow','trimf',[10610 15290 19960]);
    Fuzzy=addmf(Fuzzy,'output',1,'low','trimf',[15290 19960 24640]);
    Fuzzy=addmf(Fuzzy,'output',1,'medium','trimf',[19960 24640 29320]);
    Fuzzy=addmf(Fuzzy,'output',1,'high','trimf',[24640 29320 34000]);
    Fuzzy=addmf(Fuzzy,'output',1,'veryhigh','trimf',[29320 34000 38680]);
    
    %Initialize rules for Fuzzy
    FuzzyRules=[ ...
    1 1 1 1 1 1
    2 2 2 1 1 1
    3 3 3 3 1 1
    4 4 4 4 1 1
    5 5 5 5 1 1
    1 2 3 4 1 1
    2 3 4 5 1 1
    5 4 3 2 1 1
    4 3 2 1 1 1
    ];
    
    %add the rule-list to the fuzzy logic
    Fuzzy=addrule(Fuzzy,FuzzyRules);
    %set fuzzy to Sugeno,as the default is Mamdani
    sugenoFuzzy = mam2sug(Fuzzy); %the fuzzifier automatically set as Weighted Average
    demandData = n;
    %set the demand data to 3x34 vector consisting 3 previous hours in each
    %columns
    inputVec = [[demandData(22:24),demandData(1:21)]; ...
               [demandData(23:24),demandData(1:22)]; ...
               [demandData(24),demandData(1:23)]];
    %evaluate the fuzzy logic
    output = evalfis([inputVec], sugenoFuzzy); %output is in CFS
    fuzzyPred = hydroFormula(output);%calculate CFS to MW

function hydroPlot(predictedData,inputData)
    plot ((1:24), predictedData(1:24), '--', (1:24), inputData(1:24), 'k')
    legend('Supply Prediction','Demand')
    legend('Location','southeast')
    grid on;
    xlabel('Time (24 - Hours)');
    ylabel('in(MW)');
    set(gca,'YTick', [10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000]);
    set(gca,'XTick', [2 4 6 8 10 12 14 16 18 20 22 24]);
    set(gca, 'YTickLabel',num2str(get(gca,'YTick')'));
    xlim([1 24]);
    ylim([10000 21000])
            
function nNetPred = hydroNNetwork(demandData)
    pretrainedNN = load('preTrained.mat'); %load pre-trained NN .mat file
    pretrainedNN = pretrainedNN.pretrainedNN; %selecting variable within .mat file


    %{
    %--------------Un-comment to re-train Neural Network---------------
    inputNN = load('Input.mat'); 
    inputNN = inputNN.inputs; %load input variable for training the NN
    targetNN = load('target.mat');
    targetNN = targetNN.Target; %load target variable for training the NN

     Choosing a training function for NN
    trainFcn = 'trainbr';  % Bayesian Regularization backpropagation.

    hiddenLayerSize = 10; %Number of neuron in hidden layer
    %fitnet consists of 2 layer feedforward neural network
    pretrainedNN = fitnet(hiddenLayerSize,trainFcn); 
    pretrainedNN.layers{1}.transferFcn = 'tansig'; Tan Sigmoid hidden layer
    pretrainedNN.layers{2}.transferFcn = 'purelin'; Linear for output layer
    
    % Setup Division of Data for Training, Validation, Testing out of 72 data
    pretrainedNN.divideParam.trainRatio = 50/100; %36 samples for training
    pretrainedNN.divideParam.valRatio = 25/100; %18 samples for validation
    pretrainedNN.divideParam.testRatio = 25/100; %18 samples for testing
    
    
    pretrainedNN.trainParam.epochs = 1000;% 1000 iteration
    pretrainedNN.trainParam.max_fail = 1000; %1000 maximum validation errors
    pretrainedNN.trainParam.goal = 0; %set the MSE goal
    
    % Train the Network
    [pretrainedNN,~] = train(pretrainedNN,inputNN,targetNN);

    
    % View the Network
    %view(pretrainedNN)

    save('preTrained1.mat','pretrainedNN') %save pretrained network in .mat format
    %---------------------------------------------------------------------- 
    %}
    
    % inputVec are converting user input to vector with same format as
    % the input when training the neural network
    view(pretrainedNN)
    inputVec = [[(22:24),(1:21)];[demandData(22:24),demandData(1:21)]; ...
               [(23:24),(1:22)];[demandData(23:24),demandData(1:22)]; ...
               [24,(1:23)];[demandData(24),demandData(1:23)]];
    nnOuput = pretrainedNN(inputVec); %predict input with pre-trained nn
    nNetPred = hydroFormula(nnOuput); %output is in CFS
    %----------------------------------------------------------------------
         


% --- Executes just before hydroelectricSim is made visible.
function hydroelectricSim_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hydroelectricSim (see VARARGIN)

% Choose default command line output for hydroelectricSim
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes hydroelectricSim wait for user response (see UIRESUME)
% uiwait(handles.figure1);
 

   demandData = load('simData.mat'); %load simulation data
   demandData = demandData.simData;
   
   %insert simulation data in demand table
   set(handles.demandTable,'data',demandData);

   NNetPlot = hydroNNetwork(demandData); %pass to NN function for to predict
   axes(handles.nnPlot);
   hydroPlot(NNetPlot,demandData)% plot the NN prediction

   FLogicPlot = hydroFuzzy(demandData); %pass to FL function to predict
   axes(handles.fuzzyPlot);
   hydroPlot(FLogicPlot,demandData) %plot the FL prediction
   
   %Transpose FL vector,
   %as the data is vertical and prediction table is horizontal
   FLogicPlot1 = transpose(FLogicPlot); 
   insertTable = [NNetPlot;FLogicPlot1];%concartenate FL and NN Prediction
   set(handles.predictionTable,'data',insertTable); %insert into prediction table


% --- Outputs from this function are returned to the command line.
function varargout = hydroelectricSim_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

c = 1:24;
demand = get(handles.demandTable,'data');%get data from demand table

if(demand(c) >= 10000 & demand(c) <= 21000)
    
        neuralPred = hydroNNetwork(demand);
        axes(handles.nnPlot)
        hydroPlot(neuralPred,demand)
        
        fuzzyPred = hydroFuzzy(demand);
        axes(handles.fuzzyPlot)
        hydroPlot(fuzzyPred,demand)
        
        fuzzyPred1 = transpose(fuzzyPred);
        insertTable = [neuralPred;fuzzyPred1];
        set(handles.predictionTable,'data',insertTable);
            
else
x = demand < 10000;
y = demand > 21000;
    if (~isnan(demand) & y == 0)
        k1 = find(x);
        s1 = sprintf('%.0f,',k1); %add coma,of 0 value in the matrices
        s1 = s1(1:end-1); %stop coma at the end of matrices
        s2 = 'Demand cannot be <10000 in column : ';
        error1 = [s2 ' ' s1 ]; %concartenate string
        msgbox(error1);
    elseif (~isnan(demand) & x == 0)
        k1 = find(y);
        s1 = sprintf('%.0f,',k1);
        s1 = s1(1:end-1);
        s2 = 'Demand cannot be > 21000 in column : ';
        error2 = [s2 ' ' s1];
        msgbox(error2);
    else
        k1 = isnan(demand);
        k2 = find(k1);
        s1 = sprintf('%.0f,',k2);
        s1 = s1(1:end-1);
        s2 = 'Demand must be numerical in column : ';
        error3 = [s2 ' ' s1 ];
        msgbox(error3);
    end
end


% --- Executes on button press in resetButton.
function resetButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   PD = load('simData.mat');
   PD = PD.simData;

   NNetPlot = hydroNNetwork(PD);
   axes(handles.nnPlot);
   hydroPlot(NNetPlot,PD)

   FLogicPlot = hydroFuzzy(PD);
   axes(handles.fuzzyPlot);
   hydroPlot(FLogicPlot,PD)
   
   set(handles.demandTable,'data',PD);
   
   FLogicPlot1 = transpose(FLogicPlot);
   insertTable = [NNetPlot;FLogicPlot1];
   set(handles.predictionTable,'data',insertTable);
   
   


% --- Executes during object creation, after setting all properties.
function nnPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nnPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate nnPlot
