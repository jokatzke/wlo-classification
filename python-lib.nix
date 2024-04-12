{
  fetchgit,
  fetchFromGitLab,
  buildPythonPackage,
  numpy,
  scikit-learn,
  pandas,
  nltk,
  tensorflow,
  fastapi,
  pydantic,
  uvicorn,
  transformers,
  keras,
  nltk-data,
  gbert-base-metadata,
  wlo-classification-model
}:
let
in
buildPythonPackage {

  pname = "wlo-classification";
  version = "0.1.0";
  src = ./.;
  propagatedBuildInputs = [
    numpy
    scikit-learn
    pandas
    nltk
    tensorflow
    fastapi
    pydantic
    uvicorn
    transformers
    keras
  ];
  # set the folder for NLTK resources
  # and run the application with the model file already specified
  makeWrapperArgs = [
    "--set NLTK_DATA ${nltk-data.stopwords}"
    "--add-flags ${wlo-classification-model}"
  ];
  # use prefetched external resources
  prePatch = ''
    substituteInPlace src/*.py \
      --replace "deepset/gbert-base" "${gbert-base-metadata}"
  '';
  # this package has no tests.
  # additionally, the automatic import test fails for fastapi for some
  # reason (supposedly due to an mismatch in starlette's version), even
  # though the library works perfectly fine.
  doCheck = false;
}
