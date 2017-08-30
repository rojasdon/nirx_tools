% can get the UCL absorption spectra from 
% http://www.ucl.ac.uk/medphys/research/borl/intro/spectra
% SPM FNIRS uses the Cope thesis data for HbO HbR

% Lots of sites use extinction coefficients - then need to convert to
% absorption.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here is an example of the MBLL:
% This can be pasted into the Matlab command line.
% MAKE SURE YOU DOWNLOAD THE GetExtinctions.m FILE FIRST
% AND THAT THIS FILE IS IN THE MATLAB PATH

%Sample Data
I_w1=rand(10,1)+1;
I_w2=rand(10,1)+1;
ppf=60; dpf=6; L=3;


dOD_w1 = -log(I_w1/mean(I_w1));
dOD_w2 = -log(I_w2/mean(I_w2));

E = GetExtinctions([830 690]);  %E = [e at 830-HbO e at 830-HbR e at 830-Lipid
e at 830-H2O e at 830-AA;
                                %     e at 690-HbO e at 690-HbR e at 690-Lipid
e at 690-H2O e at 690-AA];

E=E(1:2,1:2);   %Only keep HbO/HbR parts

dOD_w1_L = dOD_w1 * ppf/(dpf*L);        %Pre-divide by pathlength (dpf,pvc
etc)
dOD_w2_L = dOD_w2 * ppf/(dpf*L);

dOD_L = [dOD_w1_L dOD_w2_L];            %Concatinate the 2(or more)
wavelengths

%I put pathlength into dOD_L so that I can preform one matrix inversion
rather than                                          %one per #measurements.
You could do inv(E*L) instead.

Einv = inv(E'*E)*E';            %Linear inversion operator (for 2 or more
wavelengths)

HbO_HbR = Einv * dOD_L';
 %Solve for HbO and HbR (This is the least-squares solution for unlimited #
of wavelengths)

HbO = HbO_HbR(1,:);
HbR = HbO_HbR(2,:);
