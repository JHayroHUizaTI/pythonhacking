import requests

query = input("What do you want to search for? ")
url = "https://www.bing.com/search?q=" + query

# Make a request to the Bing search engine
response = requests.get(url)

# Print the response
print(response.text)