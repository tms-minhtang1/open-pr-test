"""Shopping cart totals.

An item is a dict with ``name``, ``price`` and ``quantity``. ``price`` is an
integer number of cents, and money is carried as :class:`decimal.Decimal` so no
fraction of a cent ever lands in a binary float.
"""

from decimal import Decimal


def to_decimal(value):
    """Exact Decimal for a money or percentage value, without a float detour."""
    return value if isinstance(value, Decimal) else Decimal(str(value))


def subtotal(items):
    """Sum of price * quantity over every item, in cents."""
    total = Decimal(0)
    for item in items:
        total += to_decimal(item["price"]) * item["quantity"]
    return total


def apply_discount(amount, percent):
    """Reduce amount by percent, in cents.

    Raises ValueError for a percent outside 0-100, so a caller passing 150 or
    -5 fails instead of silently charging nothing or charging full price.
    """
    if not 0 <= percent <= 100:
        raise ValueError(f"percent must be between 0 and 100, got {percent}")
    return amount - amount * to_decimal(percent) / 100


def cart_summary(items, currency="USD"):
    """One line per item, for the order confirmation email."""
    lines = []
    for item in items:
        line_total = to_decimal(item["price"]) * item["quantity"]
        lines.append(f"{item['name']} x{item['quantity']}: {line_total} {currency}")
    return "\n".join(lines)
