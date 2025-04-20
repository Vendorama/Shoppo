This is a basic Shoppo search, like www.shoppo.co.nz

It just sends a request to 
https://www.shoppo.co.nz/app/?vq=all

with the search term being vq.

That's it so far, results are a JSON string with 100 results.

GET params:

    vq: the search term
    
    from: (pagination), e.g. 100 from the 100th product
    
    limit: limit the number of results, default is 100
    
    vu: vendor url, e.g. www.tasart.co.nz

    https://www.shoppo.co.nz/app/?vq=all&from=0&limit=100

results:
		'name'=>'Product Name',
		'price'=>'$1.23',
		'url'=>'https://www.website.co.nz',
		'image'=>"https://www.shoppo.co.nz/i/www.website.co.nz/images/products/00001-1_MD.jpg"

