--[[
Fluid 1.2 by SpeckDaKuhLeer

Functions:
    string text = f.encrypt(string text, string key, number salt, number runs)
    string text = f.decrypt(string text, string key, number saltLenght, number runs)
    f.setCharset(array charset)
    array charset, array reverseCharset = f.getCharset()

Weak real time symmetric encryption function for lua. Use at your own risc.
]]

-- the object that will be returned at the end
local f = {}

-- each char a numbered index
local initCharset = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
    "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H",
    "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", ",", ".", "-", "_",
    ";", ":", "+", "#", "'", "*", "(", ")", "=", "[", "]", "{", "}", "/", "!", "$", "%", "&", "?", "<", ">", "|",
    "@", " ", "~", "\\", "\n", "\""
}

-- defines a new charset
function f._initCharset(charset)
    f._charset = charset
    
    f._charsetReverse = {}
    
    for currentCharIndex in ipairs(f._charset) do
        f._charsetReverse[f._charset[currentCharIndex]] = currentCharIndex
    end
    
    f._charsetLenght = #f._charset
end

f._initCharset(initCharset)

-- rotates chars inside of the charset, a+2=c ...
function f._rotateChar(currentChar, number)
    if currentChar == nil then
        return nil
    end
    
    -- -2 and +1 because of modulo and luas stupid array handling (index starts at ... 1)
    return f._charset[((f._charsetReverse[currentChar] + number - 1) % f._charsetLenght) + 1]
end

-- converts a string into an array of chars
function f._stringToArray(givenString)
    local newArray = {}
    newArray._lenght = #givenString
    
    for currentChar = 1, newArray._lenght do
        newArray[currentChar] = string.sub(givenString, currentChar, currentChar)
    end
    
    return newArray
end

-- converts an array of chars to a string
function f._arrayToString(givenArray, lenght)
    local arrayLenght = #givenArray
    if arrayLenght > lenght then
        arrayLenght = lenght
    end
    
    local newString = ""
    
    for currentChar = 1, arrayLenght do
        newString = newString .. givenArray[currentChar]
    end
    
    return newString
end

-- reverses an array, the last field gets the first, ...
function f._reverseArray(givenArray)
    local newArray = {}
    
    for currentField = 1, givenArray._lenght do
        newArray[currentField] = givenArray[givenArray._lenght - currentField + 1]
    end
    
    newArray._lenght = givenArray._lenght
    
    return newArray
end

-- defines a new charset
function f.setCharset(newCharset)
    f._initCharset(newCharset)
end

function f.getCharset()
    return f._charset, f._charsetReverse
end

-- encrypts clear text
function f.encrypt(clearTextRaw, passphrase, salt, runs)
    local encryptedText = f._stringToArray(salt .. clearTextRaw .. "42")
    local passphraseArray = f._stringToArray(passphrase)
    
    local rotationLenght = #clearTextRaw
    
    for currentRun = 1, runs do
        for currentClearTextChar = 1, encryptedText._lenght do
            for currentPassphraseChar = 1, passphraseArray._lenght do
                currentChar = currentClearTextChar - 1 + currentPassphraseChar
                
                encryptedText[currentChar] = f._rotateChar(encryptedText[currentChar], f._charsetReverse[passphraseArray[currentPassphraseChar]])
            end
            
            encryptedText[currentClearTextChar] = f._rotateChar(encryptedText[currentClearTextChar], (currentClearTextChar * passphraseArray._lenght) % rotationLenght)
            
            if encryptedText[currentClearTextChar - 1] ~= nil then
                encryptedText[currentClearTextChar] = f._rotateChar(encryptedText[currentClearTextChar], f._charsetReverse[encryptedText[currentClearTextChar - 1]])
            end
        end
        
        encryptedText = f._reverseArray(encryptedText)
    end
    
    encryptedText = f._reverseArray(encryptedText)
    
    return f._arrayToString(encryptedText, encryptedText._lenght)
end

-- decrypts an encrypted text
function f.decrypt(encryptedText, passphrase, saltLenght, runs)
    local decryptedText = f._stringToArray(encryptedText)
    local passphraseArray = f._stringToArray(passphrase)
    
    local rotationLenght = decryptedText._lenght - saltLenght - 2
    
    for currentRun = 1, runs do
        for currentEncryptedTextChar = decryptedText._lenght, 1, -1 do
            if decryptedText[currentEncryptedTextChar - 1] ~= nil then
                decryptedText[currentEncryptedTextChar] = f._rotateChar(decryptedText[currentEncryptedTextChar], -f._charsetReverse[decryptedText[currentEncryptedTextChar - 1]])
            end
        end
        
        for currentEncryptedTextChar = 1, decryptedText._lenght do
            for currentPassphraseChar = 1, passphraseArray._lenght do
                currentChar = currentEncryptedTextChar - 1 + currentPassphraseChar
                
                decryptedText[currentChar] = f._rotateChar(decryptedText[currentChar], -f._charsetReverse[passphraseArray[currentPassphraseChar]])
            end
            
            decryptedText[currentEncryptedTextChar] = f._rotateChar(decryptedText[currentEncryptedTextChar], -((currentEncryptedTextChar * passphraseArray._lenght) % rotationLenght))
        end
    
        decryptedText = f._reverseArray(decryptedText)
    end
    
    decryptedText = f._reverseArray(decryptedText)
    
    return string.sub(f._arrayToString(decryptedText, decryptedText._lenght), saltLenght + 1, decryptedText._lenght - 2)
end

return f
