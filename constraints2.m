%%CONSTRAINTS FUNCTION
function [c, ceq]=constraints2(x)
global simul_time;

% p1 = x(1) ~ x(24);
% p2 = x(25) ~ x(48);
% p3 = x(49) ~ x(72);
% p4 = x(73) ~ x(96);
% plus minus p1 = x(97) ~ x(120)
% plus minus p2 = x(121) ~ x(144)
% plus minus p3 = x(145) ~ x(168)
% plus minus p4 = x(169) ~ x(192)

Data.A1=readtable('PVdata.xlsx','VariableNamingRule','preserve');
Data.Gen_PV = table2array(Data.A1(1:24,4))/1000;

Data.A2=readtable('ESSdata.xlsx','VariableNamingRule','preserve');
Data.ESS1 = table2array(Data.A2(1:24,3))*0.2;
Data.ESS2 = table2array(Data.A2(1:24,6))*0.2;

value = [ loadcase('case33_1') loadcase('case33_2') loadcase('case33_3') loadcase('case33_4')...
    loadcase('case33_5') loadcase('case33_6') loadcase('case33_7') loadcase('case33_8') loadcase('case33_9') ...
    loadcase('case33_10') loadcase('case33_11') loadcase('case33_12') loadcase('case33_13') loadcase('case33_14')...
    loadcase('case33_15') loadcase('case33_16') loadcase('case33_17') loadcase('case33_18') loadcase('case33_19')...
    loadcase('case33_20') loadcase('case33_21') loadcase('case33_22') loadcase('case33_23') loadcase('case33_24')];

c = zeros(48,96);

for t=1:simul_time
    if Data.Gen_PV(t,1) > 0 
%             ess1(t,1) : x(t) + x(24+t) <= Data.Gen_PV(t,1) - Data.ESS1(t,1);
%             ess2(t,1) : x(48+t) + x(72+t) = - Data.ESS2(t,1);
        if Data.ESS1(t,1) > 0
            if Data.Gen_PV(t,1) - Data.ESS1(t,1) > 0
            c(t) ~= x(t) ;
            c(t+24) ~= x(t+24);
            ceq = [];
            else 
                c(t) ~= -x(t) ;
                c(t+24) ~= -x(t+24);
                ceq = [];
            end
        else
            c(t) ~= x(t);
            c(t+24) ~= x(t+24);
            ceq = [];
        end
    else
%             ess1(t,1) : x(t) + x(24+t) = - Data.ESS1(t,1);
%             ess2(t,1) : x(48+t) + x(72+t) = - Data.ESS2(t,1);

    end
end
%             c = [];
%             ceq = [ess1(1,1); ess1(2,1); ess1(3,1); ess1(4,1); ess1(5,1); ess1(6,1); ess1(7,1); ess1(8,1); ...
%                 ess1(9,1); ess1(10,1); ess1(11,1); ess1(12,1); ess1(13,1); ess1(14,1); ess1(15,1); ess1(16,1); ...
%                 ess1(17,1); ess1(18,1); ess1(19,1); ess1(20,1); ess1(21,1); ess1(22,1); ess1(23,1); ess1(24,1); ...
%                 ess2(1,1); ess2(2,1); ess2(3,1); ess2(4,1); ess2(5,1); ess2(6,1); ess2(7,1); ess2(8,1); ...
%                 ess2(9,1); ess2(10,1); ess2(11,1); ess2(12,1); ess2(13,1); ess2(14,1); ess2(15,1); ess2(16,1); ...
%                 ess2(17,1); ess2(18,1); ess2(19,1); ess2(20,1); ess2(21,1); ess2(22,1); ess2(23,1); ess2(24,1) ];        



