# This is a python script for testing the post endpoint 
# This script should work flawlessly

import requests

#url = 'http://localhost:2000/'
url = 'http://localhost:8080/data/send?userId=100242345133661897540&type=avi'
myfiles = {'file': open('C:\\Users\\amanx\\Downloads\\test.avi' ,'rb')}
x = requests.post(url, files = myfiles, timeout=10)
x.close()

#print the response text (the content of the requested file):
print(x.text)
