import argparse

import cherrypy, json, sys

from predict import Prediction
from _version import __version__

r = None


class WebService(object):
    @cherrypy.expose
    def _ping(self):
        pass

    @cherrypy.expose
    @cherrypy.tools.json_out()
    @cherrypy.tools.json_in()
    def predict_subjects(self):
        data = cherrypy.request.json
        return {"disciplines": r.run(data["text"]), "version": __version__}


def main():
    # define CLI arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("model")
    parser.add_argument(
        "--port", action="store", default=8080, help="Port to listen on", type=int
    )
    parser.add_argument(
        "--host", action="store", default="0.0.0.0", help="Hosts to listen on", type=str
    )
    parser.add_argument(
        "--lang",
        action="store",
        default="de_DE",
        help="The language of the input text",
        type=str,
    )

    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s {version}".format(version=__version__),
    )

    # read passed CLI arguments
    args = parser.parse_args()

    modelFile = args.model

    global r
    r = Prediction(modelFile)

    # start the cherrypy service using the passed arguments
    cherrypy.server.socket_host = args.host
    cherrypy.server.socket_port = args.port
    cherrypy.quickstart(WebService())


if __name__ == "__main__":
    main()
