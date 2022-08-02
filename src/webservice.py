import cherrypy, json, sys

from predict import Prediction

r = None

class WebService(object):

   @cherrypy.expose
   @cherrypy.tools.json_out()
   @cherrypy.tools.json_in()
   def predict_subjects(self):
      data = cherrypy.request.json
      print (data)
      output = r.run(data["text"])
      return json.dumps(output)


if __name__ == '__main__':

   modelFile = sys.argv[1]
   labelFile = sys.argv[2]

   r = Prediction(modelFile, labelFile)

   config = {'server.socket_host': '0.0.0.0'}
   cherrypy.config.update(config)
   cherrypy.quickstart(WebService())	