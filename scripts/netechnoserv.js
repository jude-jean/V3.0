function afficheMenuBody(elt) {
    //elt.classList.remove('d-none');
    let idMenuBody;
    let eltMenuBody;
    console.log('elt.id = '+elt.id);
    let lstDiv = document.getElementsByTagName('div');
    for (let element of lstDiv)  {
        console.log('element.id = '+element.id);
        if(element.id.startsWith('MenuBody_')) {
            //idMenuBody = element.id.replace('Header', 'Body');
            //eltMenuBody = document.getElementById(idMenuBody);
            if(element.id.replace('Body', 'Header') != elt.id) {
                if(!element.classList.contains('d-none')) {
                    console.log('add Bootstrap class d-none');
                    element.classList.add('d-none');
                }
            }
            else {
                console.log('remove Bootstrap class d-none');
                element.classList.remove('d-none');
            }
        }
    }
    return true
}