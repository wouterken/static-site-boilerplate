addEventListener('fetch', event => {
  event.respondWith(fetchAndLog(event.request))
})

async function fetchAndLog(req) {
  let res = await fetch(req)

  if (res.status === 404 && req.method === 'GET' || req.method == 'HEAD') {
    res = new Response(res.body, {
      status: 200,
      statusText: 'OK',
      headers: res.headers,
    });
  }
  return res
}
