from google.appengine.api import users

import lib.cloudstorage as gcs
import json
import webapp2

class MainPageRedirect(webapp2.RequestHandler):
  def get(self):
    user = users.get_current_user()
    if user:
      return webapp2.redirect('/static/index.html')
    else:
      self.redirect(users.create_login_url(self.request.uri))

METRICS_DIR = '/renature-metrics-data/'

TIME_GRANULARITY = 300000 # 5-minutes

def read_metrics(metric):
  gcs_file = gcs.open(METRICS_DIR + metric + '.json')
  data = gcs_file.read()
  gcs_file.close()
  return data

def write_metrics(metric, data):
  gcs_file = gcs.open(METRICS_DIR + metric + '.json', 'w')
  gcs_file.write(json.dumps(data))
  gcs_file.close()

class DataApi(webapp2.RequestHandler):
  def get(self):
    metric = self.request.get('metric')
    cbname = self.request.get('callback')
    if metric is None or cbname is None:
      raise "missing required parameters"

    self.response.headers['Content-Type'] = 'text/javascript'
    self.response.write(cbname + '(')

    try:
      self.response.write(read_metrics(metric))
    except Exception as err:
      self.response.write(err)

    self.response.write(');')

class QueryLastApi(webapp2.RequestHandler):
  def get(self):
    metric = self.request.get('metric')
    if metric == "":
      raise "missing required parameters"
    data = json.loads(read_metrics(metric))
    self.response.write(data[len(data)-1][0])

class PublishApi(webapp2.RequestHandler):
  def get(self):
    try:
      time = int(self.request.get('time'))
      val = float(self.request.get('val'))
      metric = self.request.get('metric')
      if time is None or val is None or metric == "":
        raise "missing required parameters"

      # Snap to 5-minute granularity
      time = int(time / TIME_GRANULARITY) * TIME_GRANULARITY

      # Read existing metrics data
      data = json.loads(read_metrics(metric))
      obj = {}
      for k,v in data:
        obj[int(k)] = float(v)

      # Add new datapoint
      obj[time] = val

      # Write back to JSON
      data = []
      for k in sorted(obj.keys()):
        data.append([k, obj[k]])

      write_metrics(metric, data)
      self.response.write("Success. Wrote " + json.dumps([time, val]))
    except Exception as err:
      self.response.write(err)


app = webapp2.WSGIApplication([
  ('/', MainPageRedirect),
  ('/data.jsonp', DataApi),
  ('/publish', PublishApi),
  ('/query', QueryLastApi)
], debug=True)
