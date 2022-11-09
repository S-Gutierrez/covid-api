import pandas as pd
import json
import re
import datetime as dt


def datetime_formating(timestamp: str) -> dt:
    """
    This function transform the string with the format yyyy-Www to datetime value using the library datetime and defining day as the first day of the week.
    This formating it is also possible to be done with regex using the pattern \WW.

    arg:
        string containing timestamp in format yyyy-Www

    output:
        datetime object
    """
    timestamp = (
        dt.datetime.strptime(timestamp + "-1", "%Y-W%W-%w")
        - pd.offsets.MonthEnd(0)
        - pd.offsets.MonthBegin(1)
    )
    return timestamp


class api_pipeline(object):
    """Definition.

    TODO:

    Functionalities:
     - Build dataset
     - country_to_code - args: country: str


     Class attributes:
        -df: Dataset as pandas dataframe object
    """

    df: pd.DataFrame

    # tokenizer: transformers.models.bert.tokenization_bert_fast.BertTokenizerFast

    def __init__(self, dataset_url: str):
        """
        Initialize the pipeline loading the dataset
        """
        self.df = pd.read_csv(dataset_url)

    def country_code_test_report(self, country):
        """
        Query the top 5 articles closer to the input description.
        """
        query = json.loads(
            self.df[self.df["country_code"] == country]
            .drop(["country_code"], axis=1)
            .to_json(orient="records")
        )
        return query

    def build_dataset(self) -> None:
        """
        Processing of the data to accomodate the utility of the API
        """
        ToDrop = [
            "country",
            "level",
            "region",
            "region_name",
            "new_cases",
            "population",
            "testing_rate",
            "positivity_rate",
            "testing_data_source",
        ]
        self.df.drop(ToDrop, axis=1, inplace=True)

        self.df = self.df[
            (self.df["country_code"] == "DK")
            | (self.df["country_code"] == "DE")
            | (self.df["country_code"] == "IT")
            | (self.df["country_code"] == "ES")
            | (self.df["country_code"] == "SE")
        ]
        self.df["year_week"] = self.df["year_week"].apply(
            lambda x: str(datetime_formating(x).to_period("M"))
        )
        # Rename Columns year_week to timestamp.
        self.df.rename(columns={"year_week": "timestamp"}, inplace=True)
        self.df = self.df.groupby(["timestamp", "country_code"]).sum().reset_index()
        self.df = self.df[["country_code", "timestamp", "tests_done"]]

        group = self.df.groupby("country_code")
        country_code = group.apply(lambda x: x["country_code"].unique())
        self.country_code_dict = dict(
            zip(
                list(country_code.index),
                list(country_code.apply(lambda x: x[0]).values),
            )
        )
