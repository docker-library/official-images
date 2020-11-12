slug = require '../slug'

describe 'slug', ->
    it 'should convert input to string', ->
        [slug 1].should.eql ['1']
        [slug 567890].should.eql ['567890']

    it 'should replace whitespaces with replacement', ->
        [slug 'foo bar baz'].should.eql ['foo-bar-baz']
        [slug 'foo bar baz', '_'].should.eql ['foo_bar_baz']

    it 'should remove trailing space if any', ->
        [slug ' foo bar baz '].should.eql ['foo-bar-baz']

    it 'should remove not allowed chars', ->
        [slug 'foo, bar baz'].should.eql ['foo-bar-baz']
        [slug 'foo- bar baz'].should.eql ['foo-bar-baz']
        [slug 'foo] bar baz'].should.eql ['foo-bar-baz']

    it 'should leave allowed chars', ->
        allowed = ['*', '+', '~', '.', '(', ')', "'", '"', '!', ':', '@']
        for a in allowed
            [slug "foo #{a} bar baz"].should.eql ["foo-#{a}-bar-baz"]

    it 'should replace latin chars', ->
        char_map = {
            'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A', 'Æ': 'AE',
            'Ç': 'C', 'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ì': 'I', 'Í': 'I',
            'Î': 'I', 'Ï': 'I', 'Ð': 'D', 'Ñ': 'N', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O',
            'Õ': 'O', 'Ö': 'O', 'Ő': 'O', 'Ø': 'O', 'Ù': 'U', 'Ú': 'U', 'Û': 'U',
            'Ü': 'U', 'Ű': 'U', 'Ý': 'Y', 'Þ': 'TH', 'ß': 'ss', 'à':'a', 'á':'a',
            'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae', 'ç': 'c', 'è': 'e',
            'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
            'ð': 'd', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
            'ő': 'o', 'ø': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ű': 'u',
            'ý': 'y', 'þ': 'th', 'ÿ': 'y', 'ẞ': 'SS'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace greek chars', ->
        char_map = {
            'α':'a', 'β':'b', 'γ':'g', 'δ':'d', 'ε':'e', 'ζ':'z', 'η':'h', 'θ':'8',
            'ι':'i', 'κ':'k', 'λ':'l', 'μ':'m', 'ν':'n', 'ξ':'3', 'ο':'o', 'π':'p',
            'ρ':'r', 'σ':'s', 'τ':'t', 'υ':'y', 'φ':'f', 'χ':'x', 'ψ':'ps', 'ω':'w',
            'ά':'a', 'έ':'e', 'ί':'i', 'ό':'o', 'ύ':'y', 'ή':'h', 'ώ':'w', 'ς':'s',
            'ϊ':'i', 'ΰ':'y', 'ϋ':'y', 'ΐ':'i',
            'Α':'A', 'Β':'B', 'Γ':'G', 'Δ':'D', 'Ε':'E', 'Ζ':'Z', 'Η':'H', 'Θ':'8',
            'Ι':'I', 'Κ':'K', 'Λ':'L', 'Μ':'M', 'Ν':'N', 'Ξ':'3', 'Ο':'O', 'Π':'P',
            'Ρ':'R', 'Σ':'S', 'Τ':'T', 'Υ':'Y', 'Φ':'F', 'Χ':'X', 'Ψ':'PS', 'Ω':'W',
            'Ά':'A', 'Έ':'E', 'Ί':'I', 'Ό':'O', 'Ύ':'Y', 'Ή':'H', 'Ώ':'W', 'Ϊ':'I',
            'Ϋ':'Y'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace turkish chars', ->
        char_map = {
            'ş':'s', 'Ş':'S', 'ı':'i', 'İ':'I', 'ç':'c', 'Ç':'C', 'ü':'u', 'Ü':'U',
            'ö':'o', 'Ö':'O', 'ğ':'g', 'Ğ':'G'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace cyrillic chars', ->
        char_map = {
            'а':'a', 'б':'b', 'в':'v', 'г':'g', 'д':'d', 'е':'e', 'ё':'yo', 'ж':'zh',
            'з':'z', 'и':'i', 'й':'j', 'к':'k', 'л':'l', 'м':'m', 'н':'n', 'о':'o',
            'п':'p', 'р':'r', 'с':'s', 'т':'t', 'у':'u', 'ф':'f', 'х':'h', 'ц':'c',
            'ч':'ch', 'ш':'sh', 'щ':'sh', 'ъ':'u', 'ы':'y', 'ь':'', 'э':'e', 'ю':'yu',
            'я':'ya',
            'А':'A', 'Б':'B', 'В':'V', 'Г':'G', 'Д':'D', 'Е':'E', 'Ё':'Yo', 'Ж':'Zh',
            'З':'Z', 'И':'I', 'Й':'J', 'К':'K', 'Л':'L', 'М':'M', 'Н':'N', 'О':'O',
            'П':'P', 'Р':'R', 'С':'S', 'Т':'T', 'У':'U', 'Ф':'F', 'Х':'H', 'Ц':'C',
            'Ч':'Ch', 'Ш':'Sh', 'Щ':'Sh', 'Ъ':'U', 'Ы':'Y', 'Ь':'', 'Э':'E', 'Ю':'Yu',
            'Я':'Ya', 'Є':'Ye', 'І':'I', 'Ї':'Yi', 'Ґ':'G', 'є':'ye', 'і':'i', 'ї':'yi', 'ґ':'g'
        }
        for char, replacement of char_map
            expected = "foo-#{replacement}-bar-baz"
            expected = "foo-bar-baz" if not replacement
            [slug "foo #{char} bar baz"].should.eql [expected]

    it 'should replace czech chars', ->
        char_map = {
            'č':'c', 'ď':'d', 'ě':'e', 'ň': 'n', 'ř':'r', 'š':'s', 'ť':'t', 'ů':'u',
            'ž':'z', 'Č':'C', 'Ď':'D', 'Ě':'E', 'Ň': 'N', 'Ř':'R', 'Š':'S', 'Ť':'T',
            'Ů':'U', 'Ž':'Z'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace polish chars', ->
        char_map = {
            'ą':'a', 'ć':'c', 'ę':'e', 'ł':'l', 'ń':'n', 'ó':'o', 'ś':'s', 'ź':'z',
            'ż':'z', 'Ą':'A', 'Ć':'C', 'Ę':'e', 'Ł':'L', 'Ń':'N', 'Ś':'S',
            'Ź':'Z', 'Ż':'Z'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace latvian chars', ->
        char_map = {
            'ā':'a', 'č':'c', 'ē':'e', 'ģ':'g', 'ī':'i', 'ķ':'k', 'ļ':'l', 'ņ':'n',
            'š':'s', 'ū':'u', 'ž':'z', 'Ā':'A', 'Č':'C', 'Ē':'E', 'Ģ':'G', 'Ī':'i',
            'Ķ':'k', 'Ļ':'L', 'Ņ':'N', 'Š':'S', 'Ū':'u', 'Ž':'Z'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace currencies', ->
        char_map = {
            '€': 'euro', '₢': 'cruzeiro', '₣': 'french franc', '£': 'pound',
            '₤': 'lira', '₥': 'mill', '₦': 'naira', '₧': 'peseta', '₨': 'rupee', '₹': 'indian rupee',
            '₩': 'won', '₪': 'new shequel', '₫': 'dong', '₭': 'kip', '₮': 'tugrik',
            '₯': 'drachma', '₰': 'penny', '₱': 'peso', '₲': 'guarani', '₳': 'austral',
            '₴': 'hryvnia', '₵': 'cedi', '¢': 'cent', '¥': 'yen', '元': 'yuan',
            '円': 'yen', '﷼': 'rial', '₠': 'ecu', '¤': 'currency', '฿': 'baht',
            "$": 'dollar'
        }
        for char, replacement of char_map
            replacement = replacement.replace ' ', '-'
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace symbols', ->
        char_map = {
            '©':'(c)', 'œ': 'oe', 'Œ': 'OE', '∑': 'sum', '®': '(r)', '†': '+',
            '“': '"', '”': '"', '‘': "'", '’': "'", '∂': 'd', 'ƒ': 'f', '™': 'tm',
            '℠': 'sm', '…': '...', '˚': 'o', 'º': 'o', 'ª': 'a', '•': '*',
            '∆': 'delta', '∞': 'infinity', '♥': 'love', '&': 'and', '|': 'or',
            '<': 'less', '>': 'greater'
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace unicode', ->
        char_map = {
            '☢':"radioactive",'☠':"skull-and-bones",'☤':"caduceus",
            '☣':"biohazard",'☭':"hammer-and-sickle", '☯':"yin-yang",'☮':"peace",
            '☏':"telephone",'☔':"umbrella-with-rain-drops",'☎':"telephone",
            '☀':"sun-with-rays",'★':"star",'☂':"umbrella",'☃':"snowman",
            '✈':"airplane",'✉':"envelope",'✊':"raised-fist"
        }
        for char, replacement of char_map
            [slug "foo #{char} bar baz"].should.eql ["foo-#{replacement}-bar-baz"]

    it 'should replace no unicode when disabled', ->
        char_map = '😹☢☠☤☣☭☯☮☏☔☎☀★☂☃✈✉✊'.split ''
        for char in char_map
            [slug "foo #{char} bar baz", symbols:no].should.eql ["foo-bar-baz"]

    it 'should allow forcing lowercase slugs', ->
        [slug('FOO Bar baZ').toLowerCase()].should.eql ['foo-bar-baz']
        [slug('FOO Bar baZ', replacement:'_').toLowerCase()].should.eql ['foo_bar_baz']

    it 'should allow altering the charmap', ->
        charmap = {
            'f': 'ph', 'o':'0', 'b':'8', 'a':'4', 'r':'2', 'z':'5'
        }
        [slug("foo bar baz", {charmap}).toUpperCase()].should.eql ['PH00-842-845']
