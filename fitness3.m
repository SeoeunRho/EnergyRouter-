%% FITNESS FUNCTION:

function y=fitness3(x)

% global Data1
% global value123
% global mpopt1

% Data.A1=readtable('PVdata.xlsx','VariableNamingRule','preserve');
% Data.Gen_PV = table2array(Data.A1(1:24,5))*2;
% 
% Data.A2=readtable('ESSdata.xlsx','VariableNamingRule','preserve');
% Data.ESS1 = table2array(Data.A2(1:24,3))*0.2;
% Data.ESS2 = table2array(Data.A2(1:24,6))*0.2;
% 
% for t=1:24
% if Data.ESS1(t,1) > 0
%     Data.ESS1(t,1) = Data.ESS1(t,1)*0.95;
% else 
%     Data.ESS1(t,1) = Data.ESS1(t,1)/0.95;
% end
% end

mpopt1 = mpoption('out.lim.line',1,'verbose',0,'out.all',0,'out.bus',0,'out.branch',0);
%% bus data loading and fitting

% 1번~13번, 23,24,25번 버스는 상업지역
% 14~18, 19~22, 29~33번 버스는 거주지역
% 26~28번 버스는 학교지역
%각 BUS의 P,Q분배는 기존 33버스 부하 프로파일과 동일하게 분배 (최댓값을 1로 만들어서 기존 33번 p,q값을 곱했다는 의미)

Data1.AA=readtable('global_grid_data_LOAD.csv','VariableNamingRule','preserve');
Data1.Load = table2array(Data1.AA(1:24,2:4));

Data1.AB=readtable('GenLoad_data.xlsx','VariableNamingRule','preserve');
Data1.Tdemand = table2array(Data1.AB(1:24,2:7));  % 프로슈머 & 컨슈머 부하량
Data1.PVpro = table2array(Data1.AB(1:24,9:11));      % 프로슈머 PV 발전량 /// 해당 데이터는 이미 fitting이 이루어짐
Data1.PV(:,1) = Data1.PVpro(:,1)/max(Data1.PVpro(:,1))*3.5;
% Data.PV = table2array(Data.AB(1:24,9:11))*3.5; 
% Data1.PV = table2array(Data1.AB(1:24,9:11))*3.5;

fit.Load(:,1) = Data1.Load(:,1)/max(Data1.Load(:,1)); % 거주지역
fit.Load(:,2) = Data1.Load(:,2)/max(Data1.Load(:,2)); % 상업지역
fit.Load(:,3) = Data1.Load(:,3)/max(Data1.Load(:,3)); % 학교


%% Case Study Load Profile

abcd=loadcase('case33_1');

Case1.Bus_p = zeros(24,33);
Case1.Bus_q = zeros(24,33);

% 1~33버스 부하패턴 가져오기

for i= [1:13,23,24,25] % 1번~13번, 23,24,25번 버스는 상업지역
Case1.Bus_p(:,i) = fit.Load(:,2) * abcd.bus(i,3);
Case1.Bus_q(:,i) = fit.Load(:,2) * abcd.bus(i,4);
end


for i= [14:18,19:22,29:33] % 14~18, 19~22, 29~33번 버스는 거주지역
Case1.Bus_p(:,i) = fit.Load(:,1) * abcd.bus(i,3);
Case1.Bus_q(:,i) = fit.Load(:,1) * abcd.bus(i,4);
end


for i= 26:28 % 26~28번 버스는 학교지역
Case1.Bus_p(:,i) = fit.Load(:,3) * abcd.bus(i,3);
Case1.Bus_q(:,i) = fit.Load(:,3) * abcd.bus(i,4);
end

%% ESS 데이터 

Data1.A2=readtable('ESSdata_cms.xlsx','VariableNamingRule','preserve');
Data1.ESS1 = table2array(Data1.A2(1:24,1));
Data1.ESS2 = table2array(Data1.A2(1:24,4));

for t=1:24
if Data1.ESS1(t,1) > 0
    Data1.ESS1(t,1) = Data1.ESS1(t,1)*0.95;
else 
    Data1.ESS1(t,1) = Data1.ESS1(t,1)/0.95;
end
end

%% 프로슈머 컨슈머 부하적용 

t=1;
for i= [9 16 32 20 25 28] %프로슈머 컨슈머 부하는 9 16 32 20 24 28로 설정됨
Case1.Bus_p(:,i) = Data1.Tdemand(:,t);
t=t+1;
end


%% value 적용

for i=1:24
value123(1,i) = [ loadcase('case33_1')] ;
end



for t=1:24 % value bus 부하에 CASE1 데이터 넣기
value123(1,t).bus(:,3) = Case1.Bus_p(t,:)';
value123(1,t).bus(:,4) = Case1.Bus_q(t,:)';
end


%% PV 데이터 적용


for i=1:24
    if Data1.PVpro(i,2) > 0 %16번 버스 PV 데이터 변경
        value123(1,i).bus(16,3) = value123(1,i).bus(16,3)-Data1.PVpro(i,2);
%         value(1,i).gen(2,:) = [16  Data.PV(i,2)   0   0   0   1   100   1     0   0   0   0   0   0   0   0   0   0   0   0   0];
%         value(1,i).gencost(2,:) = [2   0   0   3   0   20   0];      
    end

    if Data1.PVpro(i,3)>0 %32번 버스 PV 데이터 변경
        value123(1,i).bus(32,3) = value123(1,i).bus(32,3)-Data1.PVpro(i,3);
%         value(1,i).gen(3,:) = [32  Data.PV(i,3)   0   0   0   1   100   1     0   0   0   0   0   0   0   0   0   0   0   0   0];
%         value(1,i).gencost(3,:) = [2   0   0   3   0   20   0];      
    end

end

for t=1:24
value123(1,t).branch(1:37,6:8) = 10;
% value123(1,t).branch(18,6:8) = 0;
% value123(1,t).branch(22,6:8) = 0;
value124(1,t).bus(1:37,12) = 0.95;
value124(1,t).bus(1:37,13) = 1.05;
end


%% fitness 시작 
for t=1:24
    case33(t) = value123(1,t);
    Case33(t,1) = runopf(case33(t),mpopt1);
%     Case33(t,1) = abcd;
    Case33(t,1).bus(20,3)= -0.95*x(t) + Case33(t,1).bus(20,3);
    Case33(t,1).bus(14,3)= -0.95*x(24+t) + Case33(t,1).bus(14,3);
    Case33(t,1).bus(24,3)= -0.95*x(48+t) + Case33(t,1).bus(24,3);
    Case33(t,1).bus(30,3)= -0.95*x(72+t) + Case33(t,1).bus(30,3);
    result1(t)=runopf(Case33(t,1),mpopt1);
    p_loss(t) = sum(real(get_losses(result1(t))))+ 0.05*(abs(x(t))+abs(x(24+t))+abs(x(48+t))+abs(x(72+t)));
    if Data1.PV(t,1) > 0
    if Data1.PV(t,1)-Data1.ESS1(t,1) > 0
        p_curt(t,1) = Data1.PV(t,1) - (x(t)+x(t+24)+Data1.ESS1(t,1));
        Object(t) = p_curt(t,1) + 0.3*p_loss(t)
        else
        p_curt(t,1) = 0;
        Object(t) = p_curt(t,1) + p_loss(t)
    end
    else
        p_curt(t,1) = 0;
        Object(t) = p_curt(t,1) + p_loss(t)
    end
end

y=sum(Object);