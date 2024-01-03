import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import datetime as dt
from scipy import stats
import jenkspy
import warnings
import os

warnings.filterwarnings("ignore")

rfm = pd.read_excel("xxxxxx\\Ashley Lough\\MBTI Minds Matter Benefit - 2024 Event Invite List (with NMF).xlsx", 'RFM DATA')

##print(stats.zscore(rfm['Days Since Last Gift']))
##print(garbage)

rfm['Rec Percentile'] = rfm['Days Since Last Gift'].rank(pct=True,ascending=False)
rfm['Recency Quartile'] = pd.qcut(rfm['Rec Percentile'], 4, labels=range(4,0,-1))
rfm['Recency Score'] = rfm['Recency Quartile'].apply(lambda x: x*5)

##rfm['Freq Percentile'] = rfm['Number of Gifts'].rank(pct=True,ascending=True)
###rfm['Frequency Score'] = pd.qcut(rfm['Freq Percentile'], 4, labels=range(2,0,-1), duplicates='drop')
##print(rfm['Freq Percentile'].unique)
###print(rfm['Frequency Score'])
##print(garbage)
##
##rfm['Mon Percentile'] = rfm['Sum Total'].rank(pct=True,ascending=False)
##rfm['Monetary Quartile'] = pd.qcut(rfm['Mon Percentile'], 4, labels=range(4,0,-1))
##rfm['Monetary Score'] = rfm['Monetary Quartile'].apply(lambda x: x*5)
##
##rfm['RFM Score'] = rfm['Recency Score'].astype(str) + rfm['Monetary Score'].astype(str) #+ (rfm['Frequency Score']*5)

print(rfm.head(3))

r_quarters = rfm['Days Since Last Gift'].quantile(q=[0.0, 0.25,0.5,0.75, 1]).to_list()
f_quarters = rfm['Number of Gifts'].quantile(q=[0.0, 0.25,0.5,0.75, 1]).to_list()
m_quarters = rfm['Sum Total'].quantile(q=[0.0, 0.25,0.5,0.75, 1]).to_list()
quartile_spread = pd.DataFrame(list(zip(r_quarters, f_quarters, m_quarters)), 
                      columns=['Q_Recency','Q_Frequency','Q_Monetary'],
                     index = ['min', 'first_part','second_part','third_part', 'max'])
print(quartile_spread)
print(garbage)

##plt.figure(figsize = (16,6))
##hist = plt.hist(rfm['Days Since Last Gift'], bins=100, align='left', color='cornflowerblue')
##for q in r_quarters:
##    plt.vlines(q, ymin=0, ymax = max(hist[0]))
##plt.show()

plt.figure(figsize = (16,6))
hist = plt.hist(rfm['Sum Total'], bins=100, align='left', color='cornflowerblue')
for q in m_quarters:
    plt.vlines(q, ymin=0, ymax = max(hist[0]))
plt.show()

print(garbage)


r_breaks = jenkspy.jenks_breaks(rfm['Days Since Last Gift'], nb_class=4)
f_breaks = jenkspy.jenks_breaks(rfm['Number of Gifts'], nb_class=4)
m_breaks = jenkspy.jenks_breaks(rfm['Sum Total'], nb_class=4)
jenks_spread = pd.DataFrame(list(zip(r_breaks, f_breaks, m_breaks)), 
                      columns=['J_Recency','J_Frequency', 'J_Monetary'],
                     index = ['min', 'first_part','second_part','third_part', 'max'])
jenks_spread
print(grabe)



rfm['RFM Score'] = (rfm['Recency Score']*5) + (rfm['Monetary Score']*5) #+ (rfm['Frequency Score']*5)


ax = rfm['rfm_score'].value_counts().plot(kind='bar', figsize=(15, 5), fontsize=12)
ax.set_xlabel("RFM Score", fontsize=12)
ax.set_ylabel("Count", fontsize=12)
plt.show()
