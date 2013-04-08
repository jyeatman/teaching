%% Dummy up a time series
%
% Rather than hope to find a time series in some data set, I thought we
% might dummy up an example so we are in full control.
%
% When a neural event occurs it does not cause a rapid peak in the BOLD
% signal, but instead there is a slow response that evolves over time
%
% We know roughly how the vascular response measured by BOLD evolves over
% time. This means that when there is an event that stimulates a brief neural
% response (say a flash of light), the resulting BOLD signal will change in
% a characteristic way. We call this the hemodynamic response function (HRF). 

% Load up a typical hemodynamic response function and plot it
load hrf.mat
plot(hrf); xlabel('Scans (2 seconds)');

%%
% First we allocate a matrix full of zeros
nTR = 100;
nStimuli = 2;
X = zeros(nTR,nStimuli); 

E1 = [12 21 41 61 86 95];
E2 = [4 32 52 69 77];

% In the first column place a one at the times when words were presented.
X(E1,1) = 1;

% In the second column place a one at the times when scrambled words were
% presented
X(E2,2) = 1;

% Build the design matrix
% The convolution isn't quite doing what I intended.  The HRF is time
% shifted.  Fix this.
dMatrix = zeros(nTR,nStimuli);
dMatrix(:,1) = conv2(X(:,1),hrf,'same');
dMatrix(:,2) = conv2(X(:,2),hrf,'same');
figure; imagesc(dMatrix ); colormap(hot)

figure; plot(dMatrix(:,1)); set(gca,'xtick',E1);
grid on

%% Simulate the time series
beta = [1, -0.3]';

% Equivalent to
% tsSimulated = beta(1)*conv2(X(:,1),hrf,'same') + beta(2)*conv2(hrf,X(:,2));
tsSimulated = dMatrix*beta;

% Figure the Signal to noise is about 1:1
mx = max(abs(tsSimulated(:)));
SNR = 20;
tsSimulated = tsSimulated + (mx/SNR)*randn(size(tsSimulated));
plot(tsSimulated)
set(gca,'xtick',sort([E1 E2]))
grid on;
xlabel('Time (sec)')
ylabel('BOLD modulation (%)')

%% Estimate the beta coefficients

% tsSimulated = dMatrix*b
% b = pinv(dMatrix)*tsSimulated

% Matlab's preferred way of solving
bEstimate = dMatrix\tsSimulated

%% Loop through the construction step and the estimation step

% Do this to see the range of beta estimates compared to the true beta
% value
%
% Try this for different SNR values.


