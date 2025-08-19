import unittest
from src.main import main

class TestMain(unittest.TestCase):
    def test_main_runs(self):
        main()  # check it runs without error

if __name__ == "__main__":
    unittest.main()
