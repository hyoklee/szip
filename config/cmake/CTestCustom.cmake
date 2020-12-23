set (CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 1500)

set (CTEST_CUSTOM_WARNING_EXCEPTION
    ${CTEST_CUSTOM_WARNING_EXCEPTION}
    "note.*expected.*void.*but argument is of type.*volatile"
    "*:[ \t]*warning"
    "POSIX name for this item is deprecated"
    "disabling jobserver mode"
    "warning.*implicit declaration of function"
    "note: expanded from macro"
)
 
set (CTEST_CUSTOM_MEMCHECK_IGNORE
    ${CTEST_CUSTOM_MEMCHECK_IGNORE}
)
