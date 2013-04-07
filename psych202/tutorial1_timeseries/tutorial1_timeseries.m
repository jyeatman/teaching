%% Examining fMRI time series
%
% Teaching objectives:
% 
% 1. Get a feeling for time series data collected in an fMRI experiment.
% What does the signal look like, how does it vary, how large is the signal
% change, how noisy etc.
%
% 2. Learn the about hemodynamic responses
%
% 3. Understand the basics of how fMRI data is analyzed using a linear
% model.
%
% 4. By the end of this tutorial each student should understand the basic
% steps that take raw fMRI data to the figures of a heatmap on the brain
% that you see in papers
%
% Author:  J. Yeatman
% Date:    April, 2013
% Tutorial duration (approximate):  1 hour
%

%%  Functional MRI Data

% In an fMRI experiment sequential brain volumes are collected while the
% stimuli and task are manipulatd. Each brain volume is a 3 dimensional
% image and each pixel in the image is called a voxel. Here is a video of a
% single slice of the brain over the course of an fMRI experiment where the
% subject was presented either words or scrambled words.

% Load the data
load data

% Open a figure window
figure; colormap('gray')
% Make a movie of slice number 10
for ii = 1:size(data,4)
    % Show the image of this slice during volume number ii
    imagesc(squeeze(data(:,:,10,ii))); 
    % pause for .2 seconds
    drawnow; pause(0.05);
end

% The intensity variation of the BOLD signal in an fMRI experiment is
% pretty small, usually less than one percent.  The noise variation is
% about the same amount, so it is difficult to see the BOLD signal in a
% simple movie like this one.

%% Analyzing the time series
% To detect a reliable change in the BOLD signal, we use signal processing
% and statistics to interpret the BOLD time series.  The key idea is to
% remove the factors that are certainly noise, and to look for signals that
% are correlated with the stimulus manipulations.

%
% change in pixel intensity over time if we extract the time series from a
% voxel in the visual cortex We can see that there is fluctuation in the
% signal over time. This is due to the blood oxygen level dependent
% contrast in these images

% Why this location?  Do we know it is a good one for this experiment?  It
% looks to me to be in primary visual cortex.
%
% Extract the time series from a voxel (x=65, y=45,z=10). 
% (The function squeeze converts the data into a vector)
ts1 = squeeze(data(65,45,10,:));

% Plot the time series for this single voxel.
figure; plot(ts1)

% Questions:
%
% 1. What are the units of the two axes?
% 2. Replot the time series with the x axis labeled in seconds. The 
% function xlabel(' ') will add a label to the axis

%% 
% These are the times when each event started. Each event lasts
% 12 seconds and there is a blank screen in between events. The timing is
% with respect to the fMRI volume number. For example 4 means that the
% event started at during the acquisition of volume number 4.
events_words    = [12 21 41 61 86 95];
events_scramble = [4 32 52 69 77 104];

% Now that we have our event times expressed in terms of scan number we can
% make an ideal time series that would reflect the expected response
% profiles for a voxel that responds to words or scrambled words. We will
% express this as a matrix with 2 columns, column 1 containing the
% predicted time series for words and column 2 containing the predicted time
% series for scrambled words. There will be 114 rows in the matrix because
% there were 114 volumes collected in the fMRI experiment.

% First we allocate a matrix full of zeros
X = zeros(114,2); 

% In the first column place a one at the times when words were presented.
X(events_words,1) = 1;

% In the second column place a one at the times when scrambled words were
% presented
X(events_scramble,2) = 1;

figure;
mx = max(ts1(:)); mn = min(ts1(:));
subplot(2,1,1),plot( (mx-mn)*X(:,1) + mn ,'r-'); hold on; plot(ts1)
subplot(2,1,2),plot( (mx-mn)*X(:,2) + mn ,'k-'); hold on; plot(ts1)


%% Show an image of the design matrix
figure; imagesc(X); colormap('gray'); ylabel('Volume Number'); 
set(gca, 'xtick',[1 2],'xticklabel', {'word' 'scramble'});

% And plot what the time series would look like
figure; hold
plot(X(:,1),'-r')
plot(X(:,2),'-b')
legend('words', 'scramble')
xlabel('Volume Number'); ylabel('Signal')

%% There is one problem with this model of the time series. When a neural
% event occurs it does not cause a rapid peak in the BOLD signal, but
% instead there is a slow response that evolves over time
%
% We know roughly how the vascular response measured by BOLD evolves over
% time. This means that when there is an event that stimulates a brief neural
% response (say a flash of light), the resulting BOLD signal will change in
% a characteristic way. We call this the hemodynamic response function (HRF). 

% Load up a typical hemodynamic response function and plot it
load hrf.mat
plot(hrf); xlabel('Scans (2 seconds)');

%% Question:
%
% 3. What does this HRF suggest about the type of cognitive questions that
% can be adressed with fMRI? For example would it be feasible to measure
% precise timing differences in the neural response to different types of
% stimuli? Based on this HRF give a few examples of questions that are and
% are not appropriate to adress with fMRI.

% We can incorporate the knowlege of this hemodynamic response function
% into our design matrix by "convolving" each event with the hrf. This
% means that rather than being represented by a brief spike, the regressors
% are now smoothed in time to match the typical hemodynamic response
X(:,1) = conv(X(:,1), hrf, 'same');
X(:,2) = conv(X(:,2), hrf, 'same');

% Now notice that the events in the design matrix are smoothed in time
% reflecting the predicted hrf.
figure; imagesc(X); colormap('gray'); ylabel('Volume Number'); 
set(gca, 'xtick',[1 2],'xticklabel', {'word' 'scramble'});
figure; hold
plot(X(:,1),'-r')
plot(X(:,2),'-b')
legend('words', 'scramble')

%% There is one more step before we fit a linear model to predict our
% measured BOLD signal based on the regressors we created around our
% experimental design. The units of the measured signal are arbitrary. We
% are interested in predicting changes in the signal over time but we do
% not care about the mean value of the time series. There are 2 ways to
% deal with this. Either subtract the mean from the signal, or add a column
% of ones to the design matrix before fitting the linear model. These two
% aproaches are equivalent


% (Though usually demeaning means pulling out a term that changes linearly
% or even quadratically over time) - BW
ts1_demeaned = ts1 - mean(ts1);

% We can now fit our linear model in which we scale each column of the
% design matrix to best fit our measured signal. 
[B, B_ci] = regress(ts1_demeaned, X);
% B = pinv(X)*ts1_demeaned

% The values in B are our beta weights. As with any regression analysis
% these are the weights that scale our regressors to best predict the
% signal. We can now plot our predicted signal agains our measured signal
ts1_predicted = X*B;
figure; hold
plot(ts1_predicted,'-r')
plot(ts1_demeaned,'-b')

%% Now we can loop over all the voxels in this slice (10) and fit this model to
% each voxel

% First loop over the first dimension (the rows)
for ii = 1:size(data,1)
    % For each row we will now loop over the columns in that row
    for jj = 1:size(data,2)
        % Pull out the time series for the voxel in row number ii of column
        % number jj in slice number 10
        ts = squeeze(data(ii,jj,10,:));
        % demean this time series
        ts_demeaned = ts - mean(ts);
        % Then fit our linear model 
        B = regress(ts_demeaned,X);
        % Now lets take the beta weight for words and put it into a matrix
        % and the weight for scrambled words and put it into another matrix
        B_words(ii,jj) = B(1);
        B_scramble(ii,jj) = B(2);
        % Calculate the model prediction for this voxel
        yhat = X*B;
        % Calculate R squared (R2) the percent of variance explained by the
        % model for this voxel
        R2(ii,jj) = calculateR2(ts_demeaned, yhat);
    end
end

%% End
