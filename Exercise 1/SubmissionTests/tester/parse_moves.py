import sys
import io
import chess.pgn

def normalize_newlines_and_encoding(pgn_input):
    # Normalize newlines
    normalized_pgn = pgn_input.replace('\r\n', '\n').replace('\r', '\n')

    # Attempt to decode the input if it's not already a string
    if isinstance(normalized_pgn, bytes):
        try:
            normalized_pgn = normalized_pgn.decode('utf-8')
        except UnicodeDecodeError:
            normalized_pgn = normalized_pgn.decode('latin-1')

    return normalized_pgn

def parse_moves(pgn_moves):
    # Normalize the input PGN string
    normalized_pgn = normalize_newlines_and_encoding(pgn_moves)

    # Read the game from the normalized PGN string
    pgn_stream = io.StringIO(normalized_pgn)
    game = chess.pgn.read_game(pgn_stream)
    
    if not game:
        print("Failed to parse PGN", file=sys.stderr)
        return []

    # Traverse the game to collect UCI moves
    node = game
    uci_moves = []
    while node.variations:
        next_node = node.variation(0)
        uci_moves.append(next_node.move.uci())
        node = next_node

    return uci_moves

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py '<pgn_moves>'", file=sys.stderr)
        sys.exit(1)

    pgn_moves = sys.argv[1]
    uci_moves = parse_moves(pgn_moves)
    
    if uci_moves:
        print(' '.join(uci_moves))
    else:
        print("No valid moves found.", file=sys.stderr)
