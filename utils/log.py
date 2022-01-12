import json
import logging.config
import pathlib
import typing

# Stack level 0 displays the information of the log message function
# Stack level 1 displays the information of the log message function
# Stack level 2 displays the information of the function that called the log message function
# Stack level 3 displays the information of the function that called the function that called the log message function
# [repeat "the function that called" as stack level increases]
STACK_LEVEL_CURRENT_FUNCTION = 1
STACK_LEVEL_DEFAULT = 2
STACK_LEVEL_PREVIOUS = 3
STACK_LEVEL_PREVIOUS_PREVIOUS = 4


logging_config_file = pathlib.Path(__file__).parent.parent.joinpath("configs", "logging.json")
logging_config = json.loads(logging_config_file.read_text())
logging.config.dictConfig(logging_config)
logger = logging.getLogger("encoder_logger")


def debug(message: typing.Any, stack_level: int = STACK_LEVEL_DEFAULT) -> None:
    logger.debug(str(message), stacklevel=stack_level)


def info(message: typing.Any, stack_level: int = STACK_LEVEL_DEFAULT) -> None:
    logger.info(str(message), stacklevel=stack_level)


def warning(message: typing.Any, stack_level: int = STACK_LEVEL_DEFAULT) -> None:
    logger.warning(str(message), stacklevel=stack_level)


def error(message: typing.Any, stack_level: int = STACK_LEVEL_DEFAULT) -> None:
    logger.error(str(message), stacklevel=stack_level)


def critical(message: typing.Any, stack_level: int = STACK_LEVEL_DEFAULT) -> None:
    logger.critical(str(message), stacklevel=stack_level)
