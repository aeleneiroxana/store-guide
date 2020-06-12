module.exports = function(words) {

    let amount = 100;
    let tuplets = [];
    let lastWord = "";
    console.log(words)
    words = words.map((word)=>word.toLowerCase());
    for(let i = 0; i < amount; i++) {
        lastWord = randomWord(words, lastWord);
        tuplets.push(createTuplet(lastWord));
    }
    return tuplets;
};

function randomWord(words, lastWord) {
    if(words.length === 1)
        return words[0];
    let index;
    do {
        index = Math.floor(Math.random() * words.length);
    }while(words[index] === lastWord);

    return words[index];
}

function createTuplet(word) {

    let original = word;
    let first = scramble(word);
    let second = obfuscate(first);
    let answer = "left";
    if(Math.random() < 0.5) {
        [first, second] = [second, first];
        answer = "right";
    }

    return {
        original,
        first,
        second,
        answer
    };
}

function scramble(word) {
    let original = word;
    do {
        word = word[0] + word.substring(1, word.length - 1).split("").shuffle().join("") + word[word.length - 1];
    } while(original === word);
    return word;
}

function obfuscate(word) {
    let alphabet = new Set();
    word.substring(1, word.length - 1).split("").forEach((el)=>{alphabet.add(el)});
    if(alphabet.size === 1) {
        let newChar = String.fromCharCode(Math.floor(Math.random() * 26) + 97);
        if(alphabet.has(newChar))
            newChar = String.fromCharCode((newChar.charCodeAt(0) - 97 + 1) % 26 + 97);
        alphabet.add(newChar);
    }
    let wordIndex = Math.floor(Math.random() * (word.length - 2)) + 1;
    alphabet.delete(word[wordIndex]);
    let setIndex = Math.floor(Math.random() * alphabet.size);
    return word.substring(0, wordIndex)
        + Array.from(alphabet.keys())[setIndex]
        + word.substring(wordIndex + 1);
}


Array.prototype.shuffle = function() {
    for (let i = this.length - 1; i > 0; i--) {
        let j = Math.floor(Math.random() * (i + 1));
        let temp = this[i];
        this[i] = this[j];
        this[j] = temp;
    }
    return this;
}
