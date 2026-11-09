
import os
import uuid
from io import BytesIO

from flask import (
    Flask, request, redirect, url_for,
    render_template_string, send_file, abort
)
from werkzeug.utils import secure_filename
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient, ContentSettings

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 100 * 1024 * 1024

# Configurações do Azure Blob Storage
STORAGE_ACCOUNT = os.environ["AZURE_STORAGE_ACCOUNT"]
CONTAINER_NAME = os.environ["AZURE_STORAGE_CONTAINER"]

account_url = f"https://{STORAGE_ACCOUNT}.blob.core.windows.net"

# Autenticação usando a identidade gerenciada da VMSS
credential = ManagedIdentityCredential()

blob_service = BlobServiceClient(
    account_url=account_url,
    credential=credential
)

container_client = blob_service.get_container_client(CONTAINER_NAME)

# Extensões permitidas
EXTENSOES = {
    "imagens": {".png", ".jpg", ".jpeg", ".gif", ".webp"},
    "videos": {".mp4", ".webm", ".mov"}
}


@app.route("/")
def home():
    return """
    <h1>Aplicação Flask - Azure</h1>
    <p>Ambiente funcionando!</p>
    <ul>
        <li><a href="/imagens">Gerenciar imagens</a></li>
        <li><a href="/videos">Gerenciar vídeos</a></li>
    </ul>
    """


@app.route("/health")
def health():
    return {"status": "healthy"}, 200


def pagina_arquivos(tipo):
    prefixo = f"{tipo}/"
    titulo = "Imagens" if tipo == "imagens" else "Vídeos"

    if request.method == "POST":
        arquivo = request.files.get("arquivo")

        if not arquivo or not arquivo.filename:
            return "Selecione um arquivo.", 400

        nome = secure_filename(arquivo.filename)
        extensao = os.path.splitext(nome)[1].lower()

        if not nome or extensao not in EXTENSOES[tipo]:
            return "Formato de arquivo não permitido.", 400

        blob_name = f"{prefixo}{uuid.uuid4().hex}_{nome}"

        blob_client = container_client.get_blob_client(blob_name)

        blob_client.upload_blob(
            arquivo.stream,
            overwrite=False,
            content_settings=ContentSettings(
                content_type=arquivo.mimetype or "application/octet-stream"
            )
        )

        return redirect(url_for(tipo))

    arquivos = list(
        container_client.list_blobs(name_starts_with=prefixo)
    )

    html = """
    <h1>{{ titulo }}</h1>

    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="arquivo" required>
        <button type="submit">Enviar arquivo</button>
    </form>

    <h2>Arquivos armazenados</h2>

    <ul>
        {% for arquivo in arquivos %}
            <li>
                <a href="/arquivo/{{ arquivo.name }}">
                    {{ arquivo.name.split('/')[-1] }}
                </a>
            </li>
        {% else %}
            <li>Nenhum arquivo enviado ainda.</li>
        {% endfor %}
    </ul>

    <a href="/">Voltar ao início</a>
    """

    return render_template_string(
        html,
        titulo=titulo,
        arquivos=arquivos
    )


@app.route("/imagens", methods=["GET", "POST"])
@app.route("/imagens/", methods=["GET", "POST"])
def imagens():
    return pagina_arquivos("imagens")


@app.route("/videos", methods=["GET", "POST"])
@app.route("/videos/", methods=["GET", "POST"])
def videos():
    return pagina_arquivos("videos")


@app.route("/arquivo/<path:blob_name>")
def baixar_arquivo(blob_name):

    if not blob_name.startswith(("imagens/", "videos/")):
        abort(404)

    blob_client = container_client.get_blob_client(blob_name)

    try:
        propriedades = blob_client.get_blob_properties()
        conteudo = blob_client.download_blob().readall()

        return send_file(
            BytesIO(conteudo),
            mimetype=propriedades.content_settings.content_type,
            download_name=blob_name.split("/")[-1]
        )

    except Exception:
        abort(404)
