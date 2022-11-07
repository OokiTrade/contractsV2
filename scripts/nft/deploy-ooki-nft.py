dev = accounts[0]
baseUrl = ""
collection = accounts[0].deploy(OokiCollection, baseUrl)
collection.setStartStamp(chain.time(), {'from': accounts[0]})
collection.pause(False, {'from': accounts[0]})

# Example
collection.mint(accounts[1], 1, {'from': accounts[2], 'value': 0.17e18})

assert collection.ownerOf(1) == accounts[1]



