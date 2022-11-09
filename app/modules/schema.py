from typing import List, Dict, Optional
from pydantic import BaseModel


# API Query Pydantic basemodel objects
class query(BaseModel):
    """
    Query text to infer
    """

    text: str


'''
class TestDone(BaseModel):
    """
    Intermediary Output class containing the information to retrieve of an item
        title
        content
        score
    """

    result: Dict[str, float]]


class EntityOut(BaseModel):
    """
    Output containing in a list the top_k inferred articles
    """

    TestReport_list: List[TestDone]
'''
