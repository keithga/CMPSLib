
# Process Flow

## (BusinessGroup)_Ready_for_PreAssessment

- Query: (None, Always true)
- Success: Move to PreAssessment
- Failure: (None)

## PreAssessment

- Query: PreAssessment Query
- Success: Move to PreCache_Compat_Scan
- Failure: Do nothing (FAILURE) - TBD Future

## PreCache_Compat_Scan

- Query: PreCache_Compat_Scan Query - TS Status Lookup, et. al.
- Success: Move to Ready_For_Scheduling
- Failure: Do nothing (FAILURE) - TBD Future

## Ready_For_Scheduling

- Query: (None Manual)
- Success: Move to Day_XX
- Failure: (None)

## DAY_XX

- Query: TS Query - TS Status Lookup, et. al.
- Success: Move to Finished
- Failure: Do nothing (FAILURE) - TBD Future

## Finished 

- Query: (None)
- Success: (None)
- Failure: (None)

