function nirx_defaults()
% PURPOSE: set directory paths and default settings for single session use so that only main
% toolbox directory needs to be on matlab path
% AUTHOR: D. Rojas
% INPUTS: none
% OUTPUTS: none
% HISTORY: 08/29/2022 - first version
%          09/01/2022 - minor path update

basedir = 'nirx_tools';

% set paths if needed
p = path;
if ~contains(p,basedir)
    addpath(p,basedir);
end
[pth,~,~] = fileparts(which('nirx_defaults'));
if ~contains(p,fullfile(basedir,'stats'))
    addpath(p,fullfile(pth,'stats'));
end
if ~contains(p,fullfile(basedir,'templates'))
    addpath(p,fullfile(pth,'templates'));
end
if ~contains(p,fullfile(basedir,'examples'))
    addpath(p,fullfile(pth,'examples'));
end

% end of main
end