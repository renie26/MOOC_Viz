clear json
%% This script is to process the "raw information" in the table, 
% e.g. final grade (1st row), the pattern sequence
% to prooduce continuous time series,
% resonable informations of suitable structure 
% and in acceptable file format for later visualization

%%% This part is optional to extract 50 prototypes by k-means 
flag0 = 1; % falg0 = 1 when processing for 50 prototypes
 if flag0 == 1
Tsize = size(Table);
[idx,C] = kmeans(transpose(Table),500);
    for i = 1:500
        for j = 1:Tsize(1)
            C(i,j) = round(C(i,j));
        end
    end
Table = transpose(C);
end
%%%

% traverse the sequence and add "Pass/Fail" state
Tsize = size(Table);
for i = 1:Tsize(2)
    if Table(1,i) < 35
        Table(12,i) = -1;
    else
        Table(12,i) = 6;
    end
    % change the last "Idle" states into "Pass/Fail" state
    for j = 11:-1:1
        if Table(j,i) == 0
            Table(j,i) = Table(12,i);
        else
            break;
        end
    end
end

% create "Patterns" and reset the numbers and order for sankey layouts
Tsize = size(Table);
Patterns = zeros(Tsize(1), Tsize(2));
% in original table, 0->idle, 1->forum researchers, 2->review videos, 
% 3-> watch new videos, 4-> combine videos and exercise, 5-> exercise only
% Intuiatively, "Pass" comes on top, so I reassign it the smallest number 0
% Similarly, change "Fail" to largest 7 
% reorder others based on results of trials, thus
% Pass->forum->combine->exercise->review->new->idle->fail
% change -1 to 7, 0 to 4, 1 to 1, 2 to 5, 3 to 3, 4 to 2, 5 to 6, 6 to 0 
for i = 1:Tsize(1)
    for j = 1: Tsize(2)
        if i ==1
            Patterns(i,j) = Table(i,j);
        else
            if(Table(i,j) == -1)
                Patterns(i,j) = 7;
            elseif(Table(i,j) == 0)
                Patterns(i,j) = 4;
            elseif(Table(i,j) == 1)
                Patterns(i,j) = 1;
            elseif(Table(i,j) == 2)
                Patterns(i,j) = 5;
            elseif(Table(i,j) == 3)
                Patterns(i,j) = 3;
            elseif(Table(i,j) == 4)
                Patterns(i,j) = 2;
            elseif(Table(i,j) == 5)
                Patterns(i,j) = 6;
            elseif(Table(i,j) == 6)
                Patterns(i,j) = 0;
            end
         end
    end
end

% extract transitions between pair of states among all users
Behaviornum = Patterns(2:Tsize(1),:);
% 88 = 8 (states) * 11 (sesions) 
transitions = zeros(88);
Bsize = size(Behaviornum);
for i = 1:Bsize(2)
    for j = 1:Bsize(1)-1
        x = Behaviornum(j,i)+1;
        y = Behaviornum(j+1,i)+1;
        X = 8*(j-1)+x;
        Y = 8*(j)+y;
        % accumulate whenever one such transition appears
        transitions(X,Y) = transitions(X,Y)+1;
    end
end

% transform the matrix-form data to following node-link-form for JSON
% {"nodes":[ {"name":"A"}, {"name":"B"}, ...], 
% "links":[ {"source":i,"target":j,"value":w}, ...]}  
Psize = size(transitions);
index = 0;
names = ['{"nodes":['];
nodes = zeros(Psize(1),1);
paths = ['"links":['];

for i = 1:Psize(1)
    flag = 0;
    for j = 1: Psize(2)
        if (transitions(i,j) ~= 0 && flag ==0 )
            week = num2str(ceil(i/8));
            label = mod(i,8);
            if label == 0
                Slabel = 'Fail'
            elseif label == 7
                Slabel = 'Inactive'
            elseif label == 6
                Slabel = 'Learner'
            elseif label == 5
                Slabel = 'Reviewer'
            elseif label == 4
                Slabel = 'Exerciser'
            elseif label == 3
                Slabel = 'F.Reader'
            elseif label == 2
                Slabel = 'F.Contributer'
            elseif label == 1
                Slabel = 'Pass'
            end
            tempname = strcat('{"name":"',Slabel,'_', week, '"},');
            names = strvcat(names, tempname);
            nodes(i) = index;
            index = index + 1;
            flag = 1;
        end
    end
end
nodes(81) = index;
nodes(88) = index+1;
names = strvcat(names, '{"name":"Pass_11"},','{"name":"Fail_11"}');

for i = 1:Psize(1)
    for j = 1: Psize(2)
        if (transitions(i,j) ~= 0 )
            source =  num2str(nodes(i));
            target =  num2str(nodes(j));
            temppath = strcat('{"source":',source,',"target":', target, ',"value":',num2str(transitions(i,j)),'},');
            paths = strvcat(paths, temppath);
        end
    end
end

tempSize = size(paths);
paths(tempSize(1),tempSize(2)) = ' ';
names = strvcat(names, '],');
paths = strvcat(paths, ']}');
% merge names and paths
json = strvcat(names,paths);
% Then output cariable json to .json file