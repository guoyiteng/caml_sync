import concurrent.futures
import urllib.request
import sys

# payload1 = ["http://127.0.0.1:8080/version?token=default" for i in range(1000)]
# payload2 = ["http://127.0.0.1:8080/diff?token=default" for i in range(1000)]
# payload3 = ["http://127.0.0.1:8080/history?token=default" for i in range(1000)]
# URLS = [payload1, payload2, payload3]
# URLS = [x for t in zip(*URLS) for x in t]
URLS = ["http://127.0.0.1:8080/version?token=default" for i in range(10000)]
# Retrieve a single page and report the url and contents
def load_url(url, timeout):
    conn = urllib.request.urlopen(url, timeout=timeout)
    return conn.read()

# We can use a with statement to ensure threads are cleaned up promptly
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    # Start the load operations and mark each future with its URL
    future_to_url = {executor.submit(load_url, url, 60): url for url in URLS}
    for future in concurrent.futures.as_completed(future_to_url):
        url = future_to_url[future]
        try:
            data = future.result() 
            # do json processing here
        except Exception as exc:
            print('%r generated an exception: %s' % (url, exc))
        else:
            print(data)
            sys.stdout.flush()