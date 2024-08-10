% PURPOSE: returns extinction coefficient for use in MBLL calculation from
% lookup tables, currently supports Cope, Moaveni, Prahl and Takatani
% (citations in mat file tables)
% AUTHOR: D. Rojas
% INPUT: wl, wavelength
%        table, 'string' (optional input, default is 'Moaveni'
% OUTPUT: ec, extinction coefficients for HbO & Hbr
% SEE ALSO: nirx_OD, nirx_DPF, nirx_MBLL
% HISTORY: 08/10/2024 - revised to output interpolated data for nice plots
%                       + bugfix for certain cases of interpolation

% Main
function [ec,iec,allwl] = nirx_ecoeff(wl,varargin)
    % defaults
    if nargin > 1
        table = varargin{1};
    else
        table = 'Moaveni';
    end
    [table_path,~,~] = fileparts(which('nirx_ecoeff.m'));
    
    switch table
        case 'Moaveni'
            table = load(fullfile(table_path,'templates','Moaveni_ecoeff.mat'));
        case 'Prahl'
            table = load(fullfile(table_path,'templates','Prahl_ecoeff.mat'));
        case 'Cope'
            table = load(fullfile(table_path,'templates','Cope_ecoeff.mat'));
        case 'Takatani'
            table = load(fullfile(table_path,'templates','Takatani_ecoeff.mat'));
        otherwise
            error('requested table does not exist!');
    end
    
    % find wavelengths (lambda), spline interpolate if not found
    min_ecoeff = min(table.ecoeffs(:,1));
    max_ecoeff = max(table.ecoeffs(:,1));
    allwl = min_ecoeff:1:max_ecoeff;
    iec(:,1) = spline(table.ecoeffs(:,1),table.ecoeffs(:,2),allwl);
    iec(:,2) = spline(table.ecoeffs(:,1),table.ecoeffs(:,3),allwl);
    for w = 1:length(wl)
        ind = find(table.ecoeffs(:,1) == wl(w));
        if ~isempty(ind)
            ec(w,:) = table.ecoeffs(ind,2:3);
        else
            if wl(w) > min_ecoeff && wl(w) < max_ecoeff
                ec(w,:) = iec(allwl == wl(w),:);
                fprintf('Wavelength not found in table. Using interpolated values for %d nm\n',wl(w));
            else
                error('%d nm is outside range of requested table!',wl);
            end
        end
    end
    fprintf('Citation: %s\n',table.citation);
end