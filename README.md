# NN EEG Covert Attention
**Task description summary:** Two squares were presented to the left and right side of fixation flickering at random (with certain restraints). At the same time a letter stream was presented to the left and right; sometimes a 2 or 5 was presented instead of letters. The participants task was cued to attend the left or right letter stream and press a button when detected a 2 or 5 at the cued, attended, side.

**Data files not included in repository**

Files for download at https://osf.io/96xsh/

`giessen_analysis.m`: filter and merge EEG data - cutout VEPs to use as features in Neural Network
- download data files in folder `EEG and experimental data` at https://osf.io/96xsh/
- download eeglab toolbox at https://sccn.ucsd.edu/eeglab/download.php

`NN EEG`: Neural Network | features = VEPs | target = attention or flash location
- download data files in folder `ERP data for Neural Net` at https://osf.io/96xsh/

#### To Do:
when the NN is unable to classify the VEPs correctly, I don't know whether this is because the NN is not appropriate or because the VEPs are not a good predictor
- generate fake data based on the assumptions we have of what happens in the brain
- train model on fake data

if the NN can classify the fake VEPs correctly
- use the model after training on the fake data, to test on the real data
- train and test this model on the real data
