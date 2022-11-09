# Import libraries
import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from modules.pipeline import api_pipeline
from modules.schema import query

app = FastAPI()


# Initialize pipeline class with url
api_pipe = api_pipeline("https://opendata.ecdc.europa.eu/covid19/testing/csv/data.csv")
# Build Dataset -> Load and process dataset
api_pipe.build_dataset()


# Define root notifying that the app is ready to use.
@app.get("/")
async def root():
    return {"message": "API Ready to use"}


# Define Search API function/Query
@app.get("/country_tests_done/")
async def extract_title(user_request: query = Depends()):

    try:

        tests_done = api_pipe.country_code_test_report(str(user_request.text))

    except:
        tests_done = ""

    if not tests_done:
        # the exception is raised, not returned - you will get a validation
        # error otherwise.
        # 2
        raise HTTPException(
            status_code=404,
            detail=f"Country code {user_request.text} not found. Check that the code follows ISO 3166-1 alpha-2",
        )

    return {f"Country {user_request.text} -Test done Record": tests_done}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5049)
