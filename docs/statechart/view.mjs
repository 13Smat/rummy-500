export const title = "A Rummy 500 turn";

const who = (seat) => (seat === "you" ? "You" : "Computer");

export const state = (v) => {
  const name = who(v.seat);
  if (v.phase === "out") return `${name} went out`;
  if (v.phase === "empty") return "The hand ends with the stock empty";
  if (v.phase === "owe") return `${name} must play the card just picked`;
  if (v.phase === "play" && v.active === 1) {
    return name === "You"
      ? "You can meld, or discard your last card"
      : "Computer can meld, or discard the last card";
  }
  if (v.phase === "play") {
    return name === "You" ? "You can meld, then discard" : "Computer can meld, then discard";
  }
  if (v.phase === "draw" && v.stock === 0) {
    return name === "You"
      ? "Your turn, and the stock is empty"
      : "Computer's turn, and the stock is empty";
  }
  return name === "You" ? "Your turn to draw" : "Computer's turn to draw";
};

const stepLabel = (from, you, computer) => (from.seat === "you" ? you : computer);

export const step = (action, from, to) => {
  switch (action) {
    case "DrawStock":
      return stepLabel(from, "you draw from the stock", "the computer draws from the stock");
    case "TakeTop":
      return stepLabel(from, "you take the top discard", "the computer takes the top discard");
    case "TakeDeep":
      return stepLabel(
        from,
        "you take a buried discard and the cards above it",
        "the computer takes a buried discard and the cards above it",
      );
    case "UsePicked":
      if (to.active === 1) {
        return stepLabel(
          from,
          "you play the picked card and one card is left",
          "the computer plays the picked card and one card is left",
        );
      }
      return stepLabel(
        from,
        "you play the picked card and keep the others",
        "the computer plays the picked card and keeps the others",
      );
    case "MeldSome":
      return stepLabel(from, "you meld a card", "the computer melds a card");
    case "MeldAll":
      return stepLabel(from, "you meld the rest of the hand", "the computer melds the rest of the hand");
    case "DiscardPass":
      return stepLabel(from, "you discard", "the computer discards");
    case "DiscardLast":
      return stepLabel(from, "you discard your last card", "the computer discards the last card");
    case "EndEmpty":
      return stepLabel(from, "you leave the discard pile", "the computer leaves the discard pile");
    default:
      return null;
  }
};

export const group = (v) => {
  if (v.phase === "out" || v.phase === "empty") return "Hand over";
  if (v.phase === "owe") return "Picked card";
  if (v.phase === "play") return "Meld or discard";
  return "Draw";
};

export const colors = {
  Draw: "blue",
  "Picked card": "orange",
  "Meld or discard": "teal",
  "Hand over": "purple",
};
