# -*- coding: utf-8 -*-
"""
Created on Fri Nov 27 15:11:56 2020

@author: nissens
"""

# target_col = -6 # attention
target_col = -7 # flash location

import tensorflow as tf
import scipy.io as spio
import pandas as pd
import numpy as np
from random import sample as rndmsample, seed as rndmseed
from math import ceil as mthceil

# load matlab data to DataFrame
mat_data = spio.loadmat('./data/ERP_data.mat')
ERP_data = mat_data['ERP_data']
df = pd.DataFrame(data=ERP_data)

# rename columns
column_names = ['fls_loc', # flash location; 0 = left, 1 = right
                'attend', # attention; 0 = unattended, 1 = attended
                'flp_t', # flip timing in nr of flips after cue
                'trial_nr', # trial the flash occured in
                'start_t', # cutout start of ERP relative to flash onset
                'stop_t', # cutout stop of ERP relative to flash onset
                'EEG_chan'] # EEG channel of the ERP
column_names_orr = df.columns.values[-len(column_names):]
df.rename(columns=dict(zip(column_names_orr,column_names)), inplace=True)

# converts dtypes of renamed columns to int
data_types = ['int64', 'int64', 'int64', 'int64', 'int64', 'int64', 'int64']
df = df.astype(dict(zip(column_names, data_types)))

# split data train - val - test: 70 - 15 - 15 based on trial_nr
# to avoid possible overtraining if x_data in train, test and val come from 
# same trial
rndmseed(119)
val_test_trnr = rndmsample(range(max(df.trial_nr)), mthceil(max(df.trial_nr) * 0.3))
val_trnr = val_test_trnr[:mthceil(len(val_test_trnr)/2)]
test_trnr = val_test_trnr[mthceil(len(val_test_trnr)/2):]

# slice 'n shuffle
train_df =  df[~df.trial_nr.isin(val_test_trnr)]
train_df = train_df.sample(frac=1, random_state=119).reset_index(drop=True)
val_df = df[df.trial_nr.isin(val_trnr)]
val_df = val_df.sample(frac=1, random_state=119).reset_index(drop=True)
test_df = df[df.trial_nr.isin(test_trnr)]
test_df = test_df.sample(frac=1, random_state=119).reset_index(drop=True)

# df to tensor
# from_tensor_slices((features_data, target_data))
# tf.data.Dataset.from_tensor_slices(
train_inputs, train_targets = (np.array(train_df.iloc[:,0:-len(column_names)].values), np.array(train_df.iloc[:,target_col].values))
val_inputs, val_targets =  (np.array(val_df.iloc[:,0:-len(column_names)].values), np.array(val_df.iloc[:,target_col].values))
test_inputs, test_targets =  (np.array(test_df.iloc[:,0:-len(column_names)].values), np.array(test_df.iloc[:,target_col].values))

# normalize inputs
normal_std = np.std(train_inputs, 0)
normal_mean = np.mean(train_inputs, 0)
train_inputs = (train_inputs - normal_mean) / normal_std
val_inputs = (val_inputs - normal_mean) / normal_std
test_inputs = (test_inputs - normal_mean) / normal_std

# NN model settings
input_size = len(train_df.iloc[0,0:-len(column_names)])
output_size = 2
output_activation = 'softmax'

hidden_layers_size = [#input_size*2,
                      #input_size,
                      round(input_size/2),
                      round(input_size/4),
                      round(input_size/8),
                      round(input_size/16),
                      round(input_size/32),
                      #round(input_size/64),
                      #round(input_size/64),
                      round(input_size/64)]
hidden_layers_activation = ['tanh',
                            'tanh',
                            'elu',
                            'elu',
                            #'elu',
                            #'elu',
                            #'elu',
                            #'elu',
                            'tanh',
                            'tanh']

# model construction
model = tf.keras.Sequential()
model.add(tf.keras.Input(shape=(input_size,)))
for layer_size, layer_act in zip(hidden_layers_size, hidden_layers_activation):
    model.add(tf.keras.layers.Dense(layer_size,
                                    activation=layer_act))
model.add(tf.keras.layers.Dense(output_size,
                                activation=output_activation))

# training settings
batch_size = 32
max_epochs = 100
nrbatches_per_epoch = mthceil(len(train_df.iloc[:,0])/batch_size)
lr_schedule = tf.keras.optimizers.schedules.ExponentialDecay(initial_learning_rate=0.01,
                                                             decay_steps=nrbatches_per_epoch*3,
                                                             decay_rate=0.9)
opt = tf.keras.optimizers.Adam(learning_rate=lr_schedule)


# compile model
model.compile(optimizer=opt,
              loss='binary_crossentropy',
              metrics=['accuracy'])


# option to print validation loss and accuracy after each batch
class print_on_end(tf.keras.callbacks.Callback):
    def __init__(self, test_data):
      self.test_data = test_data

    def on_batch_end(self, batch, logs={}):
        x, y = self.test_data
        loss, acc = self.model.evaluate(x, y, verbose=0)
        print('\nValidation loss: {}, acc: {}'.format(loss, acc))


# fit model    
model.fit(train_inputs,
          train_targets,
          batch_size=batch_size,
          epochs=max_epochs,
          validation_data=(val_inputs, val_targets),
          verbose = 2#,
          #callbacks=[print_on_end((val_inputs, val_targets))]
          )  