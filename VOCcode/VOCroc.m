function [fp,tp,auc] = VOCroc(VOCopts,id,cls,draw)

% load test set
[gtids,gt]=textread(sprintf(VOCopts.clsimgsetpath,cls,VOCopts.testset),'%s %d');

% load results
[ids,confidence]=textread(sprintf(VOCopts.clsrespath,id,cls),'%s %f');

% map results to ground truth images
out=ones(size(gt))*-inf;
tic;
for i=1:length(ids)
    % display progress
    if toc>1
        fprintf('%s: roc: %d/%d\n',cls,i,length(ids));
        drawnow;
        tic;
    end
    
    % find ground truth image
    j=strmatch(ids{i},gtids,'exact');
    if isempty(j)
        error('unrecognized image "%s"',ids{i});
    elseif length(j)>1
        error('multiple image "%s"',ids{i});
    else
        out(j)=confidence(i);
    end
end

% compute true and false positive rates
[so,si]=sort(-out);
tp=cumsum(gt(si)>0)/sum(gt>0);
fp=cumsum(gt(si)<0)/sum(gt<0);
[uo,ui]=unique(so);
tp=[0;tp(ui);1];
fp=[0;fp(ui);1];

% compute lower envelope and area under curve
di=[true ; tp(2:end-1)~=tp(1:end-2) ; true];
x=fp(di);
y=tp(di);
auc=(x(2:end)-x(1:end-1))'*y(1:end-1);

if draw
    % plot lower envelope
    xp=[0 ; reshape([x x]',[],1) ; 1 ; 1];
    yp=[0 ; 0 ; reshape([y y]',[],1) ; 1];

    plot(xp,yp,'-');
    grid;
    axis([0 1 0 1]);
    xlabel 'false positive rate'
    ylabel 'true positive rate'
    title(sprintf('class: %s, subset: %s, AUC = %.3f',cls,VOCopts.testset,auc));
end
