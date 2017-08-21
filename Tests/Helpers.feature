@helper
Feature: Write helper functions to improve code reuse and simplify

   Several helper functions are required such as epochtime converter and object to hashtable converter

   Scenario Outline: Convert standard DateTime to epochtime

   Given DateTime is <datetime>
   When I convert DateTime to Epoch
   Then Epoch is <Epoch>

   Examples: Known Epochs
   | DateTime   | Epoch         |
   | 03/03/1991 | 667958400000  |
   | 01/03/1990 | 636249600000  |
   | 13/07/2014 | 1405209600000 |
   | 21/07/2016 | 1469059200000 |

   Scenario Outline: Convert various Objects to HashTables

   Given <object> is a <type>
   When I convert <type> to hashtable
   Then Valid Hashtable is returned

   Examples: Objects
    | object                                                                                                                         | type           |
    | [pscustomobject]@{property1 = "test"; property2 = "test2"}                                                                     | pscustomobject |
    | @(([pscustomobject]@{property1 = "test"; property2 = "test2"}), ([pscustomobject]@{property1 = "test3"; property2 = "test4"})) | pscustomobject |