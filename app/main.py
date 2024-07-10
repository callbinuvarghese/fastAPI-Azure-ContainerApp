from fastapi import FastAPI, Body, HTTPException
from pydantic import BaseModel
from typing import List
from fastapi.middleware.cors import CORSMiddleware

class Album(BaseModel):
    id: int
    title: str
    artist: str
    price: float
    image_url: str

# Example initial data
albums = []

albums = [
   Album(id=1, title="You, Me and an App Id", artist="Daprize", price=10.99, image_url="https://aka.ms/albums-daprlogo"),
   Album(id=2, title="Seven Revision Army", artist="The Blue-Green Stripes", price=13.99, image_url="https://aka.ms/albums-containerappslogo"),
   Album(id=3, title="Scale It Up", artist="KEDA Club", price=13.99, image_url="https://aka.ms/albums-kedalogo"),
   Album(id=4, title="Lost in Translation", artist="MegaDNS", price=12.99,image_url="https://aka.ms/albums-envoylogo"),
]

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods="GET",
    allow_headers=["*"]
)


@app.get('/')
async def read_item():
    return {"message":"Welcome to our App"}

@app.get('/hello/{name}')
async def read_item(name):
    return {"message": f"Hello {name} Welcome to our App. How are you?"}


@app.get("/albums")
async def read_albums():
    return albums

@app.post("/albums")
async def create_album(album: Album = Body(...)):
    albums.append(album)
    return album

@app.delete("/albums/{album_id}")
def delete_item(album_id: int):
    #if album_id < 0 or album_id >= len(albums):
    #    raise HTTPException(status_code=404, detail="Album not found")
    found_index=None
    for index, val in enumerate(albums):
        if val.id == album_id:
            deleted_album = val
            found_index = index
    if not found_index:
         raise HTTPException(status_code=404, detail=f"Album not found with id:{album_id}")
    elif found_index > -1:
        albums.pop(found_index)
        return {"message": "Album deleted", "album": deleted_album}