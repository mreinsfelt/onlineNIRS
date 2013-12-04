function []=buffer_nirs(host,port,varargin);
% feed data from Artinis Oxymon to fieldtrip buffer
% 
% []=buffer_nirs(host,port,varargin);
% 
% Inputs:
%  host - [str] hostname on which the buffer server is running (localhost)
%  port - [int] port number on which to contact the server     (1972)
% Options:
%  fsample - [int] data sample rate                            (250)
%  nCh     - [int] number of channels							(24)
%  blockSize- [int] number of samples to send at a time to buffer (1)
%  Cnames   - {str} cell array of strings with the channel names in ([])
%               if empty, channel names are 'rand01', 'rand02', etc
%  stimEventRate - [int] rate in samples at which stimulated 'stimulus'  (100)
%                   events are generated 
%  queueEventRate - [int] rate (in samples) at which simulated 'queue'   (500)
%                   events are generated
%  keyboardEvents - [bool] do we listen for keyboard events and generate (1)
%                   'keyboard' events from them?
%  verb           - [int] verbosity level.  If <0 then rate in samples to print status info (0)
if ( nargin<2 || isempty(port) ) port=1972; end;
if ( nargin<1 || isempty(host) ) host='localhost'; end;
mdir=fileparts(mfilename('fullpath'));
addpath(fullfile(mdir,'buffer'));

opts=struct('fsample',250,'nCh',24,'blockSize',1,'Cnames',[],'stimEventRate',0,'queueEventRate',0,'keyboardEvents',false,'verb',0);
opts=parseOpts(opts,varargin);
if ( isempty(opts.Cnames) )
  opts.Cnames={'AD1' 'AD2' 'AD3' 'AD4' 'AD5' 'AD6' 'AD7' 'AD8' 'OD1' 'OD2' 'OD3' 'OD4' 'OD5' 'OD6' 'OD7' 'OD8' 'OD9' 'OD10' 'OD11' 'OD12' 'OD13' 'OD14' 'OD15' 'OD16'};
  for i=numel(opts.Cnames)+1:opts.nCh; opts.Cnames{i}=sprintf('rand%02d',i); end;
end

% N.B. from ft_fuffer/src/message.h: double -> ft type ID 10
hdr=struct('fsample',opts.fsample,'channel_names',{opts.Cnames},'nchans',opts.nCh,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,host,port);
dat=struct('nchans',hdr.nchans,'nsamples',opts.blockSize,'data_type',hdr.data_type,'buf',[]);
simevt=struct('type','stimulus','value',0,'sample',[],'offset',0,'duration',0);
keyevt=struct('type','keyboard','value',0,'sample',[],'offset',0,'duration',0);
fsample =opts.fsample;
blockSize=opts.blockSize;
nsamp=0; nblk=0; nevents=0; 
tic;stopwatch=toc;
% key listener
if ( opts.keyboardEvents ) 
  figure(1);set(gcf,'name','Press key here to generate events','menubar','none','toolbar','none');
  set(gcf,'keypressfcn',@keyListener);
end 


%open tmp file
[filen,path]=uigetfile('*.oxy3.tmp','Select .oxy3.tmp file');
fid=fopen(fullfile(path,filen),'r+');

clc;
fread(fid,4); %get rid of header
while( true );
  nblk=nblk+1;
  nsamp=nsamp+blockSize;
  
  loc=ftell(fid); %get current byte location
  fseek(fid,0,1); %move to end of file
  eof=ftell(fid); %save end location
  fseek(fid,loc,-1); %move back to current location
  
  if((eof-loc)>52)	
	
	%feed one line to buffer
	OD=fread(fid,16,'int16'); %this is the actual OD values
	AD=fread(fid,8,'int16'); %this is the actual AD values
	onS=fread(fid,4); %sample information and events
	
	dat.buf(1:numel(AD),:)=(-AD/8000)+4;096; %adjust data, scaling factors and offset has been calculated
	dat.buf(numel(AD)+1:numel(AD)+numel(OD))=(OD/4000);
    buffer('put_dat',dat,host,port);
	disp(dat.buf(9:14)'); %just to show that it is running
  else
	pause(.002);
  end
  
  if ( opts.verb~=0 )
    if ( opts.verb>0 || (opts.verb<0 && mod(nblk,ceil(-opts.verb/blockSize))==0) )
      fprintf('%d %d %d %f (blk,samp,event,sec)\r',nblk,nsamp,nevents,toc-stopwatch);
    end
  end  
  if ( opts.stimEventRate>0 && mod(nblk,ceil(opts.stimEventRate/blockSize))==0 )
      % insert simulated events also
      nevents=nevents+1;
      simevt.value=ceil(rand(1)*2);simevt.sample=nsamp;
      buffer('put_evt',simevt,host,port);
  end
  if ( opts.queueEventRate>0 && mod(nblk,ceil(opts.queueEventRate/blockSize))==0 )
      % insert simulated events also
      nevents=nevents+1;
      simevt.value=sprintf('queue.%d',ceil(rand(1)*2));
      simevt.sample=nsamp; 
      buffer('put_evt',simevt,host,port);
  end
  if ( opts.keyboardEvents )
      h=get(gcf,'userData');
      if ( ~isempty(h) )
          keyevt.value=h; set(gcf,'userData',[]); keyevt.sample=nsamp;
          buffer('put_evt',keyevt,host,port);
          fprintf('\nkey=%s\n',h);
      end
  end
end
return;
function []=keyListener(src,ev)
set(src,'userData',ev.Character);

%-------------
function testCase();
% start buffer server
buffer('tcpserver',struct(),'localhost',1972);
buffer_signalproxy('localhost',1972);
% now try reading data from it...
hdr=buffer('get_hdr',[],'localhost');
dat=buffer('get_dat',[],'localhost');

% generate data without making any events
buffer_signalproxy([],[],'stimEventRate',0,'queueEventRate',0,'verb',-100)

