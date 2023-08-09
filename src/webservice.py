import argparse

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from predict import Prediction
from _version import __version__

app = FastAPI()

r = None


class Data(BaseModel):
    text: str


class Result(BaseModel):
    disciplines: list[tuple[str, float]]
    version: str = __version__


@app.get("/_ping")
def _ping():
    pass


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
    prediction = Prediction(modelFile)

    @app.post("/prediction-subjects")
    def predict_subjects(data: Data) -> Result:
        return Result(disciplines=prediction.run(data.text))

    uvicorn.run("webservice:app", host=args.host, port=args.port, reload=False)


if __name__ == "__main__":
    main()
