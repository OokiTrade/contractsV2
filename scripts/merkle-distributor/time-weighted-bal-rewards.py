import csv
from decimal import *

stakePath = './stake-unstake - stake.csv'
unstakePath= './stake-unstake - unnstake.csv'

allEvents = {}
import pdb
with open(stakePath) as f:
    reader = csv.DictReader(f)
    for row in reader:
        # print(row)
        # pdb.set_trace()
        if row['user__id'] not in allEvents:
            allEvents[row['user__id']] = {'events': []}

        row['action'] = 'stake'

        allEvents[row['user__id']]['events'].append(row)
        # print(row).


with open(unstakePath) as f:
    reader = csv.DictReader(f)
    for row in reader:
        # print(row)
        # pdb.set_trace()
        if row['user__id'] not in allEvents:
            allEvents[row['user__id']] = {'events': []}

        row['action'] = 'unstake'
        row['timestamp'] = int(row['timestamp'])

        allEvents[row['user__id']]['events'].append(row)
        # print(row).

totalBPTOverTime = 0
endTime = 1629139060

for account in allEvents:
    # print('k', account)
    # pdb.set_trace()
    # walletEventsSortedByTime = sorted(allEvents[account], key=x['timestamp'], reverse=False)
    walletEvents = allEvents[account]['events']
    walletEventsSortedByTime = sorted(walletEvents, key=lambda x: (x['timestamp']), reverse=True)
    
    walletStakedOverTimeBPT = 0
    currentStaked = 0
    previousEventStartDateTime = 0
    # if account == '0xd4c0e225e5232d337d758c47415e37090ff24d17':
    #     # pdb.set_trace()
    #     pass
    for i, event in enumerate(walletEventsSortedByTime):
        # print('evemt', event)
        

        if i !=0: # previousEventStartDateTime is not stored yet
            walletStakedOverTimeBPT += currentStaked*(int(event['timestamp']) - int(previousEventStartDateTime))

        # print("walletStakedOverTimeBPT", walletStakedOverTimeBPT)
        # print("currentStaked", currentStaked)
        # pdb.set_trace()
        # pdb.set_trace()
        if event['action'] == 'stake':
            # pdb.set_trace()
            # print('amount stake', event)
            currentStaked += int(event['amount'])
        
        

        if event['action'] == 'unstake':
            # print('amount unstake', event)
            currentStaked -= int(event['amount'])
        # print('previousEventStartDateTime', previousEventStartDateTime)
        
        previousEventStartDateTime = event['timestamp']
            

        # pdb.set_trace()
    # extend untill end if any
    walletStakedOverTimeBPT += currentStaked*(endTime - int(previousEventStartDateTime))
    allEvents[account]['walletStakedOverTimeBPT'] = walletStakedOverTimeBPT

totalBPTOverTime = 0
for account in allEvents:
    # print('walletStakedOverTimeBPT', account, allEvents[account]['walletStakedOverTimeBPT'])
    totalBPTOverTime += allEvents[account]['walletStakedOverTimeBPT']

# print("totalBPTOverTime", totalBPTOverTime)

totalBalToDistribute = 674965755171273444902 # BAL.balanceOf(STAKING)
 
for account in allEvents:
    shareOverTime = allEvents[account]['walletStakedOverTimeBPT'] / float(totalBPTOverTime)
    # print("shareOverTime", shareOverTime)
    # pdb.set_trace()
    allEvents[account]['shareOverTime'] = shareOverTime
    allEvents[account]['amount'] = shareOverTime * totalBalToDistribute

print("{")
for account in allEvents:
    amount = allEvents[account]['amount']
    # print('walletStakedOverTimeBPT', account, allEvents[account]['walletStakedOverTimeBPT'], allEvents[account]['amount'])
    print(" \"{}\": {:.0f},".format(account, amount))
 
print("}")