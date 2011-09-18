function example_layout

% change this path if you install the VOC code elsewhere
addpath([cd '/VOCcode']);

% initialize VOC options
VOCinit;

% train and test layout

gtobjects=train(VOCopts);                               % train layout
test(VOCopts,gtobjects);                                % test layout
[recall,prec,ap]=VOCevallayout(VOCopts,'comp6',true);   % compute and display PR    

% train: extract all person objects with parts
function objects = train(VOCopts)

% load training set
[imgids,objids]=textread(sprintf(VOCopts.layout.imgsetpath,VOCopts.trainset),'%s %d');

% extract objects
n=0;
tic;
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('train: %d/%d\n',i,length(imgids));
        drawnow;
        tic;
    end
    
    % read annotation
    rec=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));
    
    % extract object
    n=n+1;
    objects(n)=rec.objects(objids(i));
    
    % move bounding box to origin    
    xmin=objects(n).bbox(1);
    ymin=objects(n).bbox(2);
    objects(n).bbox=objects(n).bbox-[xmin ymin xmin ymin];
    for j=1:numel(objects(n).part)
        objects(n).part(j).bbox=objects(n).part(j).bbox-[xmin ymin xmin ymin];
    end
end
    
% run layout on test images
function out = test(VOCopts,gtobjects)

% load test set
[imgids,objids]=textread(sprintf(VOCopts.layout.imgsetpath,VOCopts.testset),'%s %d');

% estimate layout for each object

GTBB=cat(1,gtobjects.bbox)';
n=0;
tic;
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('test: %d/%d\n',i,length(imgids));
        drawnow;
        tic;
    end

    % read annotation
    rec=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));

    % extract bounding box    
    bb=rec.objects(objids(i)).bbox;
    
    % move to origin
    xmin=bb(1);
    ymin=bb(2);
    bb=bb-[xmin ymin xmin ymin];
        
    % find nearest ground truth bounding box    
    d=(bb(3)-GTBB(3,:)).^2+(bb(4)-GTBB(4,:)).^2;
    [sd,si]=sort(d);

    nno=gtobjects(si);

    % copy layout from 3 nearest neighbours
    
    for nn=1:3
                  
        clear l;
        l.image=imgids{i};              % image identifier
        l.object=num2str(objids(i));    % object identifier
        l.confidence=num2str(-sd(nn));  % confidence
        nno=gtobjects(si(nn));
        for j=1:numel(nno.part)
            l.part(j).class=nno.part(j).class;                         % part class
            l.part(j).bndbox.xmin=num2str(nno.part(j).bbox(1)+xmin);   % bounding box
            l.part(j).bndbox.ymin=num2str(nno.part(j).bbox(2)+ymin);
            l.part(j).bndbox.xmax=num2str(nno.part(j).bbox(3)+xmin);
            l.part(j).bndbox.ymax=num2str(nno.part(j).bbox(4)+ymin);
        end        

        % add layout result
        n=n+1;
        xml.results.layout(n)=l;
    end
end

% write results file

fprintf('saving results...\n');
VOCwritexml(xml,sprintf(VOCopts.layout.respath,'comp6'));
