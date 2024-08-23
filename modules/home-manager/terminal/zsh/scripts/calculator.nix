{pkgs}:
pkgs.writers.writePython3Bin "=" {
  libraries = with pkgs.python312Packages; [
    click
    numexpr
  ];
} ''
  import click
  import re
  import numexpr as ne


  def show_usage() -> None:
      """Display usage information and exit."""
      click.echo("Usage: calc <expression>")
      click.echo("Example: calc '3 + 5 * (2 - 8)'")
      click.get_current_context().exit(1)


  def validate_expression(expression: str) -> None:
      """Validate the mathematical expression."""
      if not re.match(r'^[\d+\-*/().\s]+$', expression):
          click.echo(
              "Invalid expression! Only digits, spaces, and operators "
              "(+-*/().) are allowed."
          )
          show_usage()


  def calculate(expression: str) -> float:
      """Evaluate the mathematical expression."""
      try:
          result = ne.evaluate(expression).item()
      except (SyntaxError, ZeroDivisionError) as e:
          click.echo(f"Error in calculation: {e}")
          click.get_current_context().exit(1)
      except Exception as e:
          click.echo(f"Unexpected error: {e}")
          click.get_current_context().exit(1)
      return result


  @click.command(context_settings=dict(help_option_names=['-h', '--help']))
  @click.argument('expression', nargs=-1)
  def main(expression: tuple[str, ...]) -> None:
      """Simple calculator.

      Usage: calc <expression>

      Example: calc '3 + 5 * (2 - 8)'
      """
      if not expression:
          show_usage()

      expression_str = ' '.join(expression)
      validate_expression(expression_str)
      result = calculate(expression_str)
      click.echo(result)


  if __name__ == "__main__":
      main()
''
