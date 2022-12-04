%MAIN FUNCTION
% nvars = 240;
clc,clear, close all

tic
nvars = 96;

% global Data1
% global value123
% global mpopt1

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
value124(1,t).bus(1:37,12) = 0.95;
value124(1,t).bus(1:37,13) = 1.05;
end

%% 데이터 지정 끝

%% 최적화 시작 

LB = -5* ones(1,96);
UB = 5* ones(1,96);

A = zeros(24,24*4);
b = zeros(24,1);
Aeq = zeros(48,24*4);
beq = zeros(48,1);

%% 제약함수

for t=1:24
    if Data1.PV(t,1) > 0 
%             ess1(t,1) : x(t) + x(24+t) <= Data.Gen_PV(t,1) - Data.ESS1(t,1);
%             ess2(t,1) : x(48+t) + x(72+t) = - Data.ESS2(t,1);
            A(t,t) = 1;
            A(t,24+t) = 1;
            b(t,1) = Data1.PV(t,1) - Data1.ESS1(t,1);             
            Aeq(t,48+t) = 1;
            Aeq(t,72+t) = 1;
            beq(t,1) = - Data1.ESS2(t,1);
    else
%             ess1(t,1) : x(t) + x(24+t) = - Data.ESS1(t,1);
%             ess2(t,1) : x(48+t) + x(72+t) = - Data.ESS2(t,1);
            A = [];
            b = [];
            Aeq(t,t) = 1;
            Aeq(t,24+t) = 1;
            beq(t,1) = - Data1.ESS1(t,1);
            Aeq(24+t,48+t) = 1;
            Aeq(24+t,72+t) = 1;
            beq(24+t,1) = - Data1.ESS2(t,1);
    end
end

x0 = zeros(1,24*4);

ObjectiveFunction = @fitness3;
% ConstraintFunction = @constraints2;
% opts = gaoptimset(...
% 'PopulationSize', 80, ...
% 'Generations', 150, ...
% 'EliteCount', 5, ...
% 'StallGenLimit' ,400,...
% 'TolFun', 1e-8, ...
% 'PlotFcns',@gaplotpareto);
x = fmincon(ObjectiveFunction, x0, A, b, Aeq, beq, LB, UB);
p = zeros(24,4);

%% 결과 데이터 생성 

p(:,1) = x(1:24);
p(:,2) = x(25:48);
p(:,3) = x(49:72);
p(:,4) = x(73:96);

for t=1:24
    case33 = value123(1,t);
    abcdresult(t) = runopf(case33,mpopt1);
    data(t,1) = abcdresult(t);
    data(t,1).bus(20,3)= -0.95*p(t,1) + abcdresult(t).bus(20,3);       % p1 배분
    data(t,1).bus(14,3)= -0.95*p(t,2) + abcdresult(t).bus(14,3);       % p2 배분
    data(t,1).bus(24,3)= -0.95*p(t,3) + abcdresult(t).bus(24,3);       % p3 배분
    data(t,1).bus(30,3)= -0.95*p(t,4) + abcdresult(t).bus(30,3);       % p4 배분
    result1(t,1)=runopf(data(t,1),mpopt1);
    s_margin(t,1) =result1(t,1).gen(1,2);           
%     s_margin(t,2) = 1 - abs(result1(t,1).branch(14,14));
    p_loss(t,1) = sum(real(get_losses(data(t,1))))  + 0.05*(abs(p(t,1))+abs(p(t,2))+abs(p(t,3))+abs(p(t,4)));     % ER 있을 때의 PV curtailment
    if Data1.PV(t,1) > 0
        if Data1.PV(t,1)-Data1.ESS1(t,1) -(p(t,1)+p(t,2)) > 0
        p_curt(t,1) = Data1.PV(t,1) - (p(t,1)+p(t,2)+Data1.ESS1(t,1));     % ER 있을 때의 PV curtailment
        else
        p_curt(t,1) = 0;
        end
    else
        p_curt(t,1) = 0;
    end
end

%% 대조군 
for t=1:24
    origin(t,1) = value123(1,t);
%     abcdresult(t) = runopf(case33);
%     origin(t,1) = abcdresult(t);
%     [ng(t),ll] = size(origin(t,1).gen);
    if Data1.PV(t,1) > 0
    origin(t,1).gen(2,:) = zeros ;
    origin(t,1).gen(2,6) = 1 ;
    origin(t,1).gen(2,7) = 100 ;
    origin(t,1).gen(2,8) = 1 ;
    origin(t,1).gen(2,9) = Data1.PV(t,1);
    origin(t,1).gen(2,2) = Data1.PV(t,1);
    origin(t,1).gen(2,1) = 14 ;
    origin(t,1).gencost(2,:) = zeros;
    origin(t,1).gencost(2,1) = 2;
    else
    end
    if Data1.ESS1(t,1) > 0
            origin(t,1).bus(14,3) = origin(t,1).bus(14,3)- Data1.ESS1(t,1);
    elseif Data1.ESS1(t,1) < 0
        origin(t,1).bus(14,3) = origin(t,1).bus(14,3)- Data1.ESS1(t,1);
    end
    if Data1.ESS2(t,1) > 0
        origin(t,1).bus(30,3) = origin(t,1).bus(30,3) - Data1.ESS2(t,1);
    elseif Data1.ESS2(t,1) < 0 
            origin(t,1).bus(30,3) = origin(t,1).bus(30,3) - Data1.ESS2(t,1);
    else
    end
    abc(t,1)=runopf(origin(t,1),mpopt1);
    s_margin_origin(t,1) = abc(t,1).gen(1,2);
%     s_margin_origin(t,2) = 2 - abc(t,1).branch(13,16));
    if Data1.PV(t,1) > 0 
    p_curt_origin(t,1)=Data1.PV(t,1) - abc(t,1).gen(2,2);
    else
        p_curt_origin(t,1)=0;
    end
    p_loss_origin(t,1) = sum(real(get_losses(abc(t,1))));
end

% for t=1:24
%     
%     if Data.PV(t,1) - Data.ESS1(t,1) > 0
%     origin(t,1).gen(ng(t)+1,2) = Data.PV(t,1) - Data.ESS1(t,1) - p_curt_origin(t,1) ;
%     else
%     end
%     abc_2(t,1)=runpf(origin(t,1));
% %     s_margin_origin(t,1) = 0.8 - ((abc_2(t,1).branch(14,14))^2+(abc_2(t,1).branch(14,15))^2)^0.5;
% %     s_margin_origin(t,2) = 0.8 - ((abc_2(t,1).branch(13,16))^2+(abc_2(t,1).branch(13,17))^2)^0.5;
%     s_margin_origin(t,1) = 3 - abs(abc_2(t,1).branch(1,14));
% %     s_margin_origin(t,2) =1  - abs(abc_2(t,1).branch(14,14));
%     p_loss_origin(t,1) = sum(real(get_losses(origin(t,1))));
% end



p_curt_bar = [];
for t=7:20
p_curt_bar1 = [p_curt_origin(t,1) p_curt(t,1)];
p_curt_bar = [p_curt_bar; p_curt_bar1];
end
t = 7:20;
figure(2)
hold on 
bar(t,p_curt_bar)
plot(t,Data1.PV(t,1),'r')
legend('case1', 'case2', 'Solar profile')
title("PV curtailment")
xlabel('Time(Hour)')
ylabel('Power(MW)')
hold off

p_penetration_bar = [];
for t=7:20
p_penetration_bar1 = [((Data1.PV(t,1)-p_curt_origin(t,1))/sum(origin(t,1).bus(:,3)))*100 (Data1.PV(t,1)/sum(origin(t,1).bus(:,3)))*100];
p_penetration_bar = [p_penetration_bar; p_penetration_bar1];
end
t = 7:20;
figure(3)
hold on 
bar(t,p_penetration_bar)
legend('case1', 'case2')
title("PV penetration")
xlabel('Time(Hour)')
ylabel('Rate(%)')
hold off

p_loss_bar = [];
for t=1:24
p_loss_bar1 = [p_loss_origin(t,1) p_loss(t,1)];
p_loss_bar = [p_loss_bar; p_loss_bar1];
end
t = 1:24;
figure(4)
hold on 
bar(t,p_loss_bar)
legend('case1', 'case2')
title("P loss")
xlabel('Time(Hour)')
ylabel('Power(MW)')
hold off

s_margin_bar = [];
for t=1:24
s_margin_bar1 = [s_margin_origin(t,1) s_margin(t,1)];
s_margin_bar = [s_margin_bar; s_margin_bar1];
end
t = 1:24;
figure(5)
hold on 
bar(t,s_margin_bar)
legend('case1', 'case2')
title("Power from grid")
xlabel('Time(Hour)')
ylabel('Power(MW)')
hold off


toc